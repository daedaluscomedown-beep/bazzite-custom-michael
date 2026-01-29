#!/bin/bash

set -ouex pipefail

echo "--- STARTING CUSTOM BUILD ---"

# ==============================================================================
# 1. DISABLE TERRA REPOS (From disable-terra.sh)
# ==============================================================================
echo "--- Disabling Terra Repositories ---"
# This prevents conflicts during the build process
for repo_file in $(find /etc/yum.repos.d /usr/etc/yum.repos.d -name "*terra*.repo" 2>/dev/null); do
    echo "Disabling repo: $repo_file"
    sed -i 's/enabled=1/enabled=0/g' "$repo_file"
done

# ==============================================================================
# 2. INSTALL PACKAGES (From recipe.yml modules)
# ==============================================================================
echo "--- Installing RPM Packages ---"

# Define your packages
PACKAGES=(
    "ryzenadj"
    "alsa-firmware"
    "lact"
)

# Install them
rpm-ostree install "${PACKAGES[@]}"

# ==============================================================================
# 3. APPLY KERNEL ARGUMENTS (From kargs.sh)
# ==============================================================================
echo "--- Applying Kernel Arguments via Config File ---"

# instead of running rpm-ostree kargs, we write a static config file.
# This is the stable, "bootc" compliant way to do it.

KARGS_FILE="/usr/lib/kernel/cmdline.d/99-michael-custom.conf"
mkdir -p "$(dirname "$KARGS_FILE")"

cat <<EOF > "$KARGS_FILE"
# Michael's Custom Kargs
split_lock_detect=off
amdgpu.ppfeaturemask=0xffffffff
drm.edid_firmware=DP-3:edid/samsung_g5_custom.bin
video=DP-3:e
EOF

echo "Created $KARGS_FILE"

# ==============================================================================
# 4. SYSTEM TWEAKS (From tweaks.sh)
# ==============================================================================
echo "--- Applying Final System Tweaks ---"

# Ensure MIME database sees Chrome as default
if [ -d "/usr/share/mime" ]; then
    update-mime-database /usr/share/mime
fi

# Enable the Undervolt Service (Assumes unit file was copied via 'files/etc/systemd/system')
systemctl --global enable undervolt.service

echo "--- BUILD COMPLETE ---"