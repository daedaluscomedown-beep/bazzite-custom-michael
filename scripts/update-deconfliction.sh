#!/bin/bash
# System Update & Tuning Script for Deconfliction OS
# Logic: Check Service -> Enable if needed -> Apply Formula 1 Tuning

echo "🚀 Starting Deconfliction Maintenance..."
echo "-----------------------------------"

# 1. KARGS CHECK (Automation)
# Note: Monitor EDID overrides REMOVED for Razer Raptor support
if ! grep -q "amd_pstate=active" /proc/cmdline; then
    echo "⚙️  Performance Tunables missing. Applying now..."
    rpm-ostree kargs \
      --append-if-missing=nowatchdog \
      --append-if-missing=amd_pstate=active \
      --append-if-missing=split_lock_detect=off \
      --append-if-missing=amdgpu.ppfeaturemask=0xffffffff 
    echo "✅ Kernel Tunables applied."
    NEED_REBOOT=1
fi

# 2. SERVICE CHECK (The Gatekeeper)
if ! systemctl is-enabled lactd.service &> /dev/null; then
    echo "⚙️  LACT Service is OFF. Enabling now..."
    systemctl enable --now lactd.service
    echo "✅ LACT Service enabled."
else
    echo "✅ LACT Service is already active."
fi

# 2.5 STABILITY CHECK (Kill OOMD)
# Prevents Fedora from killing games during RAM spikes.
if systemctl is-enabled systemd-oomd &> /dev/null; then
    echo "💀 Neutralizing Systemd-OOMD (Stability Fix)..."
    systemctl disable --now systemd-oomd
    systemctl mask systemd-oomd
    echo "✅ Systemd-OOMD masked."
else
    echo "✅ Systemd-OOMD is already neutralized."
fi

# 3. GPU TUNING (The Formula 1 Tweak)
LACT_CONFIG="/etc/lact/config.yaml"
# Dynamic detection for PowerColor RX 9070
GPU_ID=$(ls /sys/class/drm/ | grep "card[0-9]$" | xargs -I {} readlink -f /sys/class/drm/{} | awk -F'/' '{print $NF}' | grep -E "^[0-9a-f]{4}:" | head -n 1)

if [ -z "$GPU_ID" ]; then
    echo "⚠️  No AMD GPU found. Skipping Tuning."
else
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
        - [40, 0.0]
        - [50, 0.30]
        - [60, 0.50]
        - [70, 0.75]
        - [80, 1.0]
      pmfw:
        acoustic_limit: 2200
        acoustic_target: 1200
        target_temp: 85
        zero_rpm: true
EOF
        # Restart required to apply the config we just wrote
        systemctl restart lactd.service
        echo "✅ Tuning Applied & Service Restarted."
    else
        echo "✅ GPU Config exists. Keeping current settings."
    fi
fi

# 4. NextDNS Check (Reminder)
if [ -f "/usr/bin/nextdns" ] && ! systemctl is-active nextdns &> /dev/null; then
    echo "ℹ️  NextDNS binary is installed. Run 'sudo nextdns install' to configure if needed."
fi

# 5. Update Applications & System
echo "📦 Updating Applications..."
flatpak update -y

if command -v install-ge-proton.sh &> /dev/null; then
    install-ge-proton.sh
fi

echo "💿 Updating System..."
echo "Q" | /usr/bin/ujust update

echo "-----------------------------------"
if [ "$NEED_REBOOT" = "1" ]; then
    echo "⚠️  IMPORTANT: Updates applied that require a REBOOT."
else
    echo "✅ Maintenance Complete."
fi
read -p "Press Enter to exit..."