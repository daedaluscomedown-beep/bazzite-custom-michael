FROM ghcr.io/ublue-os/bazzite:stable

# ---------------------------------------------------------------------------
# 1. GOLD MASTER PERFORMANCE TUNING (Systemd Environment)
# ---------------------------------------------------------------------------
RUN mkdir -p /etc/environment.d && \
    echo 'AMD_VULKAN_ICD=radv' > /etc/environment.d/90-gaming.conf && \
    echo 'RADV_DEBUG=aco' >> /etc/environment.d/90-gaming.conf && \
    echo 'RADV_PERFTEST=gpl,sam,video_decode,nggc,rt,antilag2' >> /etc/environment.d/90-gaming.conf && \
    echo 'RADV_RT_PIPELINE_CACHE=1' >> /etc/environment.d/90-gaming.conf && \
    echo 'VKD3D_CONFIG=no_upload_hvv' >> /etc/environment.d/90-gaming.conf && \
    echo 'PROTON_USE_NTSYNC=1' >> /etc/environment.d/90-gaming.conf && \
    echo 'PROTON_NO_WGI=1' >> /etc/environment.d/90-gaming.conf && \
    echo 'STEAM_FORCE_DESKTOPUI_SCALING=auto' >> /etc/environment.d/90-gaming.conf && \
    echo 'MESA_SHADER_CACHE_MAX_SIZE=20G' >> /etc/environment.d/90-gaming.conf && \
    echo 'MESA_SHADER_CACHE_DIR=/var/lib/mesa' >> /etc/environment.d/90-gaming.conf && \
    echo 'MESA_SHADER_CACHE_SINGLE_FILE=1' >> /etc/environment.d/90-gaming.conf && \
    echo 'SCB_AUTO_HDR=1' >> /etc/environment.d/90-gaming.conf && \
    echo 'SCB_AUTO_VRR=1' >> /etc/environment.d/90-gaming.conf && \
    echo 'SCB_AUTO_RES=1' >> /etc/environment.d/90-gaming.conf

# Global Wayland Vars
RUN echo 'SDL_VIDEODRIVER=wayland' > /etc/environment.d/96-wayland.conf && \
    echo 'CLUTTER_BACKEND=wayland' >> /etc/environment.d/96-wayland.conf && \
    echo 'MOZ_ENABLE_WAYLAND=1' >> /etc/environment.d/96-wayland.conf

RUN mkdir -p /var/lib/mesa && chmod 1777 /var/lib/mesa

# ---------------------------------------------------------------------------
# 2. LOW LEVEL TUNING (Sysctl / NVMe / ZRAM / CPU)
# ---------------------------------------------------------------------------
# A. Sysctl (X3D Optimized)
RUN mkdir -p /usr/lib/sysctl.d && \
    echo 'vm.swappiness=15' > /usr/lib/sysctl.d/99-gaming.conf && \
    echo 'vm.vfs_cache_pressure=50' >> /usr/lib/sysctl.d/99-gaming.conf && \
    echo 'vm.dirty_ratio=15' >> /usr/lib/sysctl.d/99-gaming.conf && \
    echo 'vm.dirty_background_ratio=5' >> /usr/lib/sysctl.d/99-gaming.conf && \
    echo 'kernel.sched_latency_ns=6000000' >> /usr/lib/sysctl.d/99-gaming.conf && \
    echo 'kernel.sched_min_granularity_ns=750000' >> /usr/lib/sysctl.d/99-gaming.conf && \
    echo 'net.ipv4.tcp_congestion_control=bbr' >> /usr/lib/sysctl.d/99-gaming.conf && \
    echo 'net.core.default_qdisc=cake' >> /usr/lib/sysctl.d/99-gaming.conf

RUN echo sch_cake > /etc/modules-load.d/cake.conf

# B. NVMe Scheduler (Force 'none' for shader stability)
RUN echo 'ACTION=="add|change", KERNEL=="nvme*n*", ATTR{queue/scheduler}="none"' > /etc/udev/rules.d/60-nvme-scheduler.rules

# C. ZRAM Optimization
RUN echo '[zram0]' > /etc/systemd/zram-generator.conf && \
    echo 'zram-size = ram / 2' >> /etc/systemd/zram-generator.conf && \
    echo 'compression-algorithm = zstd' >> /etc/systemd/zram-generator.conf && \
    echo 'swap-priority = 100' >> /etc/systemd/zram-generator.conf

# D. CPU Governor Enforcer Service
RUN echo '[Unit]' > /etc/systemd/system/cpu-performance.service && \
    echo 'Description=Force CPU Governor Performance' >> /etc/systemd/system/cpu-performance.service && \
    echo 'After=multi-user.target' >> /etc/systemd/system/cpu-performance.service && \
    echo '[Service]' >> /etc/systemd/system/cpu-performance.service && \
    echo 'Type=oneshot' >> /etc/systemd/system/cpu-performance.service && \
    echo 'ExecStart=/usr/bin/cpupower frequency-set -g performance' >> /etc/systemd/system/cpu-performance.service && \
    echo '[Install]' >> /etc/systemd/system/cpu-performance.service && \
    echo 'WantedBy=multi-user.target' >> /etc/systemd/system/cpu-performance.service

RUN systemctl enable cpu-performance.service

# ---------------------------------------------------------------------------
# 3. PACKAGES & REPOS (FIXED)
# ---------------------------------------------------------------------------
# Add LACT Repo
RUN curl -fsSL https://copr.fedorainfracloud.org/coprs/ilyaz/LACT/repo/fedora-$(rpm -E %fedora)/ilyaz-LACT.repo \
    -o /etc/yum.repos.d/ilyaz-LACT.repo

# DISABLE TERRA (Fixes 404 build errors)
RUN sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/terra.repo || true && \
    sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/terra-mesa.repo || true

# INSTALL PACKAGES
# Removed: mangohud, goverlay (Built-in to Bazzite)
# Removed: protonup-qt (Install as Flatpak post-boot)
# Removed: distribution-gpg-keys (Built-in)
RUN rpm-ostree install \
    lact \
    && rm -rf /var/cache/rpms

# SCOPEBUDDY
RUN curl -fsSL "https://raw.githubusercontent.com/HikariKnight/ScopeBuddy/main/bin/scopebuddy" -o /usr/bin/scopebuddy && \
    chmod +x /usr/bin/scopebuddy && \
    ln -sf /usr/bin/scopebuddy /usr/bin/scb

# ---------------------------------------------------------------------------
# 4. LACT HARDENING & POWER MANAGEMENT
# ---------------------------------------------------------------------------
# Disable power-profiles-daemon so LACT can rule
RUN systemctl mask power-profiles-daemon.service

# Race Condition Fix
RUN mkdir -p /etc/systemd/system/lactd.service.d && \
    echo '[Unit]' > /etc/systemd/system/lactd.service.d/override.conf && \
    echo 'After=systemd-udev-settle.service' >> /etc/systemd/system/lactd.service.d/override.conf && \
    echo 'Wants=systemd-udev-settle.service' >> /etc/systemd/system/lactd.service.d/override.conf

# Dynamic Config Script
RUN echo '#!/bin/bash' > /usr/bin/setup-lact.sh && \
    echo 'CARD=$(ls /sys/class/drm | grep "^card[0-9]$" | sort | head -n1)' >> /usr/bin/setup-lact.sh && \
    echo '[ -z "$CARD" ] && exit 0' >> /usr/bin/setup-lact.sh && \
    echo 'mkdir -p /etc/lact' >> /usr/bin/setup-lact.sh && \
    echo 'cat <<EOF > /etc/lact/config.yaml' >> /usr/bin/setup-lact.sh && \
    echo 'daemon:' >> /usr/bin/setup-lact.sh && \
    echo '  log_level: info' >> /usr/bin/setup-lact.sh && \
    echo '  admin_groups: [wheel, sudo]' >> /usr/bin/setup-lact.sh && \
    echo '  apply_on_startup: true' >> /usr/bin/setup-lact.sh && \
    echo 'gpus:' >> /usr/bin/setup-lact.sh && \
    echo '  "$CARD":' >> /usr/bin/setup-lact.sh && \
    echo '    fan_control_enabled: true' >> /usr/bin/setup-lact.sh && \
    echo '    fan_control_mode: curve' >> /usr/bin/setup-lact.sh && \
    echo 'EOF' >> /usr/bin/setup-lact.sh && \
    echo 'systemctl restart lactd' >> /usr/bin/setup-lact.sh && \
    chmod +x /usr/bin/setup-lact.sh

# Setup Service
RUN echo '[Unit]' > /etc/systemd/system/lact-setup.service && \
    echo 'Description=Generate LACT Config for GPU' >> /etc/systemd/system/lact-setup.service && \
    echo 'After=systemd-udev-settle.service' >> /etc/systemd/system/lact-setup.service && \
    echo 'Before=lactd.service' >> /etc/systemd/system/lact-setup.service && \
    echo '[Service]' >> /etc/systemd/system/lact-setup.service && \
    echo 'Type=oneshot' >> /etc/systemd/system/lact-setup.service && \
    echo 'ExecStart=/usr/bin/setup-lact.sh' >> /etc/systemd/system/lact-setup.service && \
    echo '[Install]' >> /etc/systemd/system/lact-setup.service && \
    echo 'WantedBy=multi-user.target' >> /etc/systemd/system/lact-setup.service

RUN systemctl enable lactd.service && \
    systemctl enable lact-setup.service

# ---------------------------------------------------------------------------
# 5. NEXTDNS
# ---------------------------------------------------------------------------
RUN NEXTDNS_URL=$(curl -s https://api.github.com/repos/nextdns/nextdns/releases/latest | grep browser_download_url | grep linux_amd64.tar.gz | cut -d '"' -f 4) && \
    curl -fsSL "$NEXTDNS_URL" -o /tmp/nextdns.tar.gz && \
    tar -xzf /tmp/nextdns.tar.gz -C /usr/bin nextdns && \
    chmod +x /usr/bin/nextdns && \
    rm /tmp/nextdns.tar.gz

RUN mkdir -p /etc/nextdns && \
    echo 'auto-activate true' > /etc/nextdns/config && \
    echo 'cache-size 10MB' >> /etc/nextdns/config && \
    echo 'timeout 5s' >> /etc/nextdns/config

RUN echo '[Unit]' > /etc/systemd/system/nextdns.service && \
    echo 'Description=NextDNS DNS53 to DoH proxy' >> /etc/systemd/system/nextdns.service && \
    echo 'ConditionFileNotEmpty=/etc/nextdns/config' >> /etc/systemd/system/nextdns.service && \
    echo 'After=network-online.target' >> /etc/systemd/system/nextdns.service && \
    echo 'Wants=network-online.target' >> /etc/systemd/system/nextdns.service && \
    echo '' >> /etc/systemd/system/nextdns.service && \
    echo '[Service]' >> /etc/systemd/system/nextdns.service && \
    echo 'ExecStart=/usr/bin/nextdns run -config /etc/nextdns/config' >> /etc/systemd/system/nextdns.service && \
    echo 'Restart=on-failure' >> /etc/systemd/system/nextdns.service && \
    echo 'RestartSec=5s' >> /etc/systemd/system/nextdns.service && \
    echo '' >> /etc/systemd/system/nextdns.service && \
    echo '[Install]' >> /etc/systemd/system/nextdns.service && \
    echo 'WantedBy=multi-user.target' >> /etc/systemd/system/nextdns.service

RUN systemctl enable nextdns.service

# ---------------------------------------------------------------------------
# 6. CLEANUP
# ---------------------------------------------------------------------------
RUN rm -rf /var/cache/rpms /var/cache/dnf