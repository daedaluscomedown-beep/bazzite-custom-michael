FROM ghcr.io/ublue-os/bazzite:stable

# ==============================================================================
# 1. ENVIRONMENT — GPU / PROTON / WAYLAND
# ==============================================================================
RUN mkdir -p /etc/environment.d && \
    cat > /etc/environment.d/90-gaming.conf << 'EOF'
AMD_VULKAN_ICD=radv
RADV_DEBUG=aco
RADV_PERFTEST=gpl,sam,video_decode,nggc,rt,antilag2
RADV_RT_PIPELINE_CACHE=1

PROTON_USE_NTSYNC=1
PROTON_NO_WGI=1

MESA_SHADER_CACHE_MAX_SIZE=20G
MESA_SHADER_CACHE_DIR=/var/lib/mesa
MESA_SHADER_CACHE_SINGLE_FILE=1

STEAM_FORCE_DESKTOPUI_SCALING=auto

SCB_AUTO_HDR=1
SCB_AUTO_VRR=1
SCB_AUTO_RES=1
EOF

# Wayland globals
RUN cat > /etc/environment.d/96-wayland.conf << 'EOF'
SDL_VIDEODRIVER=wayland
CLUTTER_BACKEND=wayland
MOZ_ENABLE_WAYLAND=1
EOF

RUN mkdir -p /var/lib/mesa && chmod 1777 /var/lib/mesa

# ==============================================================================
# 2. SYSTEM STABILITY — SYSCTL / ZRAM / NVME
# ==============================================================================
RUN mkdir -p /usr/lib/sysctl.d && \
    cat > /usr/lib/sysctl.d/99-gaming.conf << 'EOF'
vm.swappiness=1
vm.vfs_cache_pressure=50
vm.dirty_ratio=15
vm.dirty_background_ratio=5
vm.max_map_count=2147483642
fs.inotify.max_user_watches=524288
kernel.hung_task_timeout_secs=120
net.ipv4.tcp_congestion_control=bbr
net.core.default_qdisc=cake
EOF

RUN echo sch_cake > /etc/modules-load.d/cake.conf

# NVMe: none scheduler
RUN cat > /etc/udev/rules.d/60-nvme-scheduler.rules << 'EOF'
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
EOF

# ZRAM (8GB max)
RUN cat > /etc/systemd/zram-generator.conf << 'EOF'
[zram0]
zram-size = min(ram / 3, 8192)
compression-algorithm = zstd
swap-priority = 100
EOF

# ==============================================================================
# 3. GE-PROTON — AUTOMATIC SYSTEM UPDATES
# ==============================================================================
RUN mkdir -p /usr/libexec && \
    cat > /usr/libexec/update-ge-proton.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="/usr/share/steam/compatibilitytools.d"
TMP="$(mktemp -d)"

JSON="$(curl -fsSL https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest)"
URL="$(echo "$JSON" | grep browser_download_url | grep tar.gz | cut -d '"' -f 4)"
VERSION="$(basename "$URL" .tar.gz)"

mkdir -p "$INSTALL_DIR"
cd "$TMP"
curl -fsSL "$URL" -o ge.tar.gz
tar -xzf ge.tar.gz

find "$INSTALL_DIR" -maxdepth 1 -type d -name "GE-Proton*" ! -name "$VERSION" -exec rm -rf {} +
mv "$VERSION" "$INSTALL_DIR/"
chmod -R a+rX "$INSTALL_DIR/$VERSION"

rm -rf "$TMP"
EOF

RUN chmod +x /usr/libexec/update-ge-proton.sh

RUN cat > /etc/systemd/system/ge-proton-update.service << 'EOF'
[Unit]
Description=Update GE-Proton
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/libexec/update-ge-proton.sh
EOF

RUN cat > /etc/systemd/system/ge-proton-update.timer << 'EOF'
[Unit]
Description=Daily GE-Proton Update

[Timer]
OnBootSec=10min
OnUnitActiveSec=24h
Persistent=true

[Install]
WantedBy=timers.target
EOF

RUN systemctl enable ge-proton-update.timer

# ==============================================================================
# 4. PACKAGES & LACT
# ==============================================================================
RUN curl -fsSL https://copr.fedorainfracloud.org/coprs/ilyaz/LACT/repo/fedora-$(rpm -E %fedora)/ilyaz-LACT.repo \
    -o /etc/yum.repos.d/ilyaz-LACT.repo

RUN rpm-ostree install lact htop nvtop && rm -rf /var/cache/rpms

# Disable power-profiles-daemon (LACT owns power)
RUN systemctl mask power-profiles-daemon.service

# LACT ordering fix
RUN mkdir -p /etc/systemd/system/lactd.service.d && \
    cat > /etc/systemd/system/lactd.service.d/override.conf << 'EOF'
[Unit]
After=multi-user.target
Requires=multi-user.target
EOF

RUN systemctl enable lactd.service

# ==============================================================================
# 5. CLEANUP
# ==============================================================================
RUN systemctl mask abrtd.service
RUN rm -rf /var/cache/rpms /var/cache/dnf
RUN bootc container lint || true
