#!/bin/bash
# System Update & Tuning Script for Deconfliction OS

echo "🚀 Starting Deconfliction Maintenance..."
echo "-----------------------------------"

# 1. KARGS CHECK (Automation)
# Checks if your 5800X3D and Monitor fixes are active. If not, applies them.
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
else
    echo "✅ Kernel Tunables are active."
fi

# 2. SERVICE CHECK (LACT)
# Checks if the LACT fan control service is enabled.
if ! systemctl is-enabled lactd.service &> /dev/null; then
    echo "⚙️  Enabling LACT Service..."
    systemctl enable --now lactd.service
    echo "✅ LACT Service enabled."
else
    echo "✅ LACT Service is active."
fi

# 3. Update Flatpaks
echo "📦 Updating Applications..."
flatpak update -y

# 4. Update Proton
if command -v install-ge-proton.sh &> /dev/null; then
    install-ge-proton.sh
fi

# 5. System Update
echo "💿 Updating System..."
echo "Q" | /usr/bin/ujust update

echo "-----------------------------------"
if [ "$NEED_REBOOT" = "1" ]; then
    echo "⚠️  IMPORTANT: Updates applied that require a REBOOT."
else
    echo "✅ Maintenance Complete."
fi
read -p "Press Enter to exit..."