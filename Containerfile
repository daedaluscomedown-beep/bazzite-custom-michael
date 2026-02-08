FROM ghcr.io/ublue-os/bazzite:stable

# ---------------------------------------------------------------------------
# 1. PLATINUM PERFORMANCE TUNING (/usr/etc/environment)
# ---------------------------------------------------------------------------
RUN mkdir -p /usr/etc && \
    echo 'AMD_VULKAN_ICD=radv' >> /usr/etc/environment && \
    echo 'RADV_PERFTEST=gpl,sam,video_decode,nggc,rt' >> /usr/etc/environment && \
    echo 'RADV_RT_PIPELINE_CACHE=1' >> /usr/etc/environment && \
    echo 'ENABLE_LAYER_MESA_ANTI_LAG=1' >> /usr/etc/environment && \
    echo 'VKD3D_CONFIG=no_upload_hvv' >> /usr/etc/environment && \
    echo 'PROTON_USE_NTSYNC=1' >> /usr/etc/environment && \
    echo 'STEAM_FORCE_DESKTOPUI_SCALING=auto' >> /usr/etc/environment && \
    echo 'MESA_SHADER_CACHE_MAX_SIZE=20G' >> /usr/etc/environment && \
    echo 'MESA_SHADER_CACHE_DIR=/var/lib/mesa' >> /usr/etc/environment && \
    echo 'MESA_SHADER_CACHE_SINGLE_FILE=1' >> /usr/etc/environment

# Ensure the cache directory exists
RUN mkdir -p /var/lib/mesa && chmod 1777 /var/lib/mesa

# ---------------------------------------------------------------------------
# 2. SYSCTL TUNING (Latency & Safety)
# ---------------------------------------------------------------------------
RUN mkdir -p /usr/lib/sysctl.d && \
    echo 'vm.swappiness=1' > /usr/lib/sysctl.d/99-gaming.conf && \
    echo 'vm.vfs_cache_pressure=50' >> /usr/lib/sysctl.d/99-gaming.conf && \
    echo 'vm.max_map_count=262144' >> /usr/lib/sysctl.d/99-gaming.conf && \
    echo 'net.ipv4.tcp_congestion_control=bbr' >> /usr/lib/sysctl.d/99-gaming.conf && \
    echo 'net.core.default_qdisc=cake' >> /usr/lib/sysctl.d/99-gaming.conf

# ---------------------------------------------------------------------------
# 3. GAMEMODE CONFIGURATION
# ---------------------------------------------------------------------------
RUN mkdir -p /usr/share/gamemode && \
    echo '[general]' > /usr/share/gamemode/gamemode.ini && \
    echo 'renice=10' >> /usr/share/gamemode/gamemode.ini && \
    echo 'ioprio=0' >> /usr/share/gamemode/gamemode.ini

# ---------------------------------------------------------------------------
# 4. PACKAGE INSTALLATION
# ---------------------------------------------------------------------------
# A. LACT Repo
RUN curl -fsSL https://copr.fedorainfracloud.org/coprs/ilyaz/LACT/repo/fedora-$(rpm -E %fedora)/ilyaz-LACT.repo \
    -o /etc/yum.repos.d/ilyaz-LACT.repo

# B. Install Packages
RUN rpm-ostree install \
    lact \
    mangohud \
    goverlay \
    distribution-gpg-keys \
    && rm -rf /var/cache/rpms

# C. Enable LACT Service
RUN ln -s /usr/lib/systemd/system/lactd.service \
    /usr/lib/systemd/system/multi-user.target.wants/lactd.service

# ---------------------------------------------------------------------------
# 5. NEXTDNS (Hardened Service & Dynamic Fetch)
# ---------------------------------------------------------------------------
# Fetch Latest Tarball & Extract Binary
RUN NEXTDNS_URL=$(curl -s https://api.github.com/repos/nextdns/nextdns/releases/latest | grep browser_download_url | grep linux_amd64.tar.gz | cut -d '"' -f 4) && \
    curl -fsSL "$NEXTDNS_URL" -o /tmp/nextdns.tar.gz && \
    tar -xzf /tmp/nextdns.tar.gz -C /usr/bin nextdns && \
    chmod +x /usr/bin/nextdns && \
    rm /tmp/nextdns.tar.gz

# Config
RUN mkdir -p /etc/nextdns && \
    echo 'auto-activate true' > /etc/nextdns/config && \
    echo 'cache-size 10MB' >> /etc/nextdns/config && \
    echo 'timeout 5s' >> /etc/nextdns/config

# Service
RUN echo '[Unit]' > /etc/systemd/system/nextdns.service && \
    echo 'Description=NextDNS DNS53 to DoH proxy' >> /etc/systemd/system/nextdns.service && \
    echo 'ConditionFileNotEmpty=/etc/nextdns/config' >> /etc/systemd/system/nextdns.service && \
    echo 'After=network-online.target' >> /etc/systemd/system/nextdns.service && \
    echo 'Wants=network-online.target' >> /etc/systemd/system/nextdns.service && \
    echo '' >> /etc/systemd/system/nextdns.service && \
    echo '[Service]' >> /etc/systemd/system/nextdns.service && \
    echo 'ExecStart=/usr/bin/nextdns run' >> /etc/systemd/system/nextdns.service && \
    echo 'Restart=on-failure' >> /etc/systemd/system/nextdns.service && \
    echo 'RestartSec=5s' >> /etc/systemd/system/nextdns.service && \
    echo '' >> /etc/systemd/system/nextdns.service && \
    echo '[Install]' >> /etc/systemd/system/nextdns.service && \
    echo 'WantedBy=multi-user.target' >> /etc/systemd/system/nextdns.service

# Enable NextDNS
RUN ln -s /etc/systemd/system/nextdns.service \
    /etc/systemd/system/multi-user.target.wants/nextdns.service

# ---------------------------------------------------------------------------
# 6. PROTON-GE (System-Wide)
# ---------------------------------------------------------------------------
COPY scripts/install-ge-proton.sh /tmp/install-ge-proton.sh
RUN chmod +x /tmp/install-ge-proton.sh && \
    /tmp/install-ge-proton.sh && \
    rm /tmp/install-ge-proton.sh

# ---------------------------------------------------------------------------
# 7. CLEANUP
# ---------------------------------------------------------------------------
RUN rm -rf /var/cache/rpms /var/cache/dnf