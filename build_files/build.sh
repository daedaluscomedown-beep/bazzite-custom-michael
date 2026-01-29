#!/bin/bash

set -ouex pipefail

echo "=== STARTING DECONFLICTION BUILD (v3) === "

# ==============================================================================
# 1. ADD LACT REPO (The Missing Step!)
# ==============================================================================
echo "Adding LACT Copr repository..."

# We write the repo file directly to ensure it exists
cat <<EOF > /etc/yum.repos.d/lact.repo
[copr:copr.fedorainfracloud.org:igorszymanski:lact]
name=Copr repo for lact owned by igorszymanski
baseurl=https://download.copr.fedorainfracloud.org/results/igorszymanski/lact/fedora-\$releasever-\$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://download.copr.fedorainfracloud.org/results/igorszymanski/lact/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
EOF

# ==============================================================================
# 2. INSTALL PACKAGES
# ==============================================================================
echo "Installing packages..."

PACKAGES=(
    # --- System Tools ---
    "tmux"
    "htop"
    "nvtop"
    
    # --- Hardware Optimization ---
    "ryzenadj"       # CPU Undervolting
    "alsa-firmware"  # Audio Fixes
    "lact"           # GPU Control (System Service Version)
    "corectrl"       # Alternative Control
    
    # --- Storage / RAID ---
    "fio"
    "mdadm"
    "nvme-cli"
)

# Install everything
rpm-ostree install "${PACKAGES[@]}"

# ==============================================================================
# 3. ENABLE SERVICES
# ==============================================================================
echo "Enabling system services..."
systemctl enable podman.socket
systemctl enable lactd  # This ensures your GPU settings apply on boot!

# ==============================================================================
# 4. CLEANUP
# ==============================================================================
# Disable Terra repos to prevent conflicts
for repo_file in $(find /etc/yum.repos.d /usr/etc/yum.repos.d -name "*terra*.repo" 2>/dev/null); do
    sed -i 's/enabled=1/enabled=0/g' "$repo_file"
done

echo "=== Build complete ==="