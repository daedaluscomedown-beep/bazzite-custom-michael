#!/bin/bash
# System Update & Tuning Script for Deconfliction OS
# Logic: Check Service -> Enable if needed -> Apply Formula 1 Tuning

echo "🚀 Starting Deconfliction Maintenance..."
echo "-----------------------------------"

# 1. KARGS CHECK (Automation)
if ! grep -q "amd_pstate=active" /proc/cmdline; then
    echo "⚙️  Performance Tunables missing. Applying now..."
    rpm-ostree kargs \
      --append-if-missing=nowatchdog \
      --append-if-missing=amd_pstate=active \
      --append-if-missing=split_lock_detect=off \
      --append-if-missing=amdgpu.ppfeaturemask=0xffffffff \
      --append-if-missing=drm.edid_firmware=DP-1:edid/samsung_g5_custom.bin \
      --append-if-missing=drm.edid_firmware=DP-2:edid/samsung_g5_custom.bin \
      --append-if-missing=drm.edid_firmware=DP-3:edid/samsung_g5_custom.bin
    echo "✅ Kernel Tunables applied."
    NEED_REBOOT=1
fi

# 2. SERVICE CHECK (The Gatekeeper)
# We ensure the service is running BEFORE we try to configure it.
if ! systemctl is-enabled lactd.service &> /dev/null; then
    echo "⚙️  LACT Service is OFF. Enabling now..."
    systemctl enable --now lactd.service
    echo "✅ LACT Service enabled."
else
    echo "✅ LACT Service is already active."
fi

# 3. GPU TUNING (The Formula 1 Tweak)
# Now that the service is confirmed active, we apply the 269W/-70mV config.
LACT_CONFIG="/etc/lact/config.yaml"
# Dynamic GPU ID Detection (Finds the 9070 regardless of slot)
GPU_ID=$(ls /sys/class/drm/ | grep "card[0-9]$" | xargs -I {} readlink -f /sys/class/drm/{} | awk -F'/' '{print $NF}' | grep -E "^[0-9a-f]{4}:" | head -n 1)

if [ -z "$GPU_ID" ]; then
    echo "⚠️  No AMD GPU found. Skipping Tuning."
else
    # Only write config if it doesn't exist (Safety First)
    if [ ! -f "$LACT_CONFIG" ]; then
        echo "⚡ Applying RX 9070 Config: 269W Limit, -70mV Undervolt, Custom Curve..."
        mkdir -p /etc/lact

cat <<EOF > $LACT_CONFIG
daemon:
  log_level: info
  admin_group: wheel
gpus:
  "$GPU_ID":
    power_cap: 269.0
    voltage_offset: -70
    performance_level: manual
    fan_control:
      mode: curve
      static_speed: 0.5
      curve:
        - [40, 0.0]   # Silent below 40C
        - [50, 0.30]  # 30% at 50C
        - [60, 0.50]  # 50% at 60C
        - [70, 0.75]  # 75% at 70C
        - [80, 1.0]   # Max thrust at 80C
      pmfw:
        acoustic_limit: 2200
        acoustic_target: 1200
        target_temp: 85
        zero_rpm: true
EOF
        # We MUST restart the service for it to read the new config
        systemctl restart lactd.service
        echo "✅ Tuning Applied & Service Restarted."
    else
        echo "✅ GPU Config exists. Keeping current settings."
    fi
fi

# 4. Update Flatpaks
echo "📦 Updating Applications..."
flatpak update -y

# 5. Update Proton
if command -v install-ge-proton.sh &> /dev/null; then
    install-ge-proton.sh
fi

# 6. System Update
echo "💿 Updating System..."
echo "Q" | /usr/bin/ujust update

echo "-----------------------------------"
if [ "$NEED_REBOOT" = "1" ]; then
    echo "⚠️  IMPORTANT: Updates applied that require a REBOOT."
else
    echo "✅ Maintenance Complete."
fi
read -p "Press Enter to exit..."