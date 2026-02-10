FROM ghcr.io/ublue-os/bazzite:stable

# ---------------------------------------------------------------------------
# 1. PLATINUM PERFORMANCE TUNING (Atomic-Safe Profile)
# ---------------------------------------------------------------------------
# We use /etc/profile.d to ensure these apply to all user sessions reliably.
RUN mkdir -p /etc/profile.d && \
    echo 'export AMD_VULKAN_ICD=radv' > /etc/profile.d/gaming.sh && \
    echo 'export RADV_PERFTEST=gpl,sam,video_decode,nggc,rt' >> /etc/profile.d/gaming.sh && \
    echo 'export RADV_RT_PIPELINE_CACHE=1' >> /etc/profile.d/gaming.sh && \
    echo 'export ENABLE_LAYER_MESA_ANTI_LAG=1' >> /etc/profile.d/gaming.sh && \
    echo 'export VKD3D_CONFIG=no_upload_hvv' >> /etc/profile.d/gaming.sh && \
    echo 'export PROTON_USE_NTSYNC=1' >> /etc/profile.d/gaming.sh && \
    echo 'export STEAM_FORCE_DESKTOPUI_SCALING=auto' >> /etc/profile.d/gaming.sh && \
    echo 'export MESA_SHADER_CACHE_MAX_SIZE=20G' >> /etc/profile.d/gaming.sh && \
    # Updated: Per-User Cache Directory for safety
    echo 'export MESA_SHADER_CACHE_DIR=/var/lib/mesa/\$UID' >> /etc/profile.d/gaming.sh && \
    echo 'export MESA_SHADER_CACHE_SINGLE_FILE=1' >> /etc/profile.d/gaming.sh && \
    # SCOPEBUDDY GLOBAL VARS
    echo 'export SCB_AUTO_HDR=1' >> /etc/profile.d/gaming.sh && \
    echo 'export SCB_AUTO_VRR=1' >> /etc/profile.d/gaming.sh && \
    echo 'export SCB_AUTO_RES=1' >> /etc/profile.d/gaming.sh && \
    chmod +x /etc/profile.d/gaming.sh

RUN mkdir -p /var/lib/mesa && chmod 1777 /var/lib/mesa

# ---------------------------------------------------------------------------
# 2. SYSCTL & GAMEMODE
# ---------------------------------------------------------------------------
RUN mkdir -p /usr/lib/sysctl.d && \
    echo 'vm.swappiness=1' > /usr/lib/sysctl.d/99-gaming.conf && \
    echo 'vm.vfs_cache_pressure=50' >> /usr/lib/sysctl.d/99-gaming.conf && \
    echo 'vm.max_map_count=262144' >> /usr/lib/sysctl.d/99-gaming.conf && \
    echo 'net.ipv4.tcp_congestion_control=bbr' >> /usr/lib/sysctl.d/99-gaming.conf && \
    echo 'net.core.default_qdisc=cake' >> /usr/lib/sysctl.d/99-gaming.conf

# Load CAKE module
RUN echo sch_cake > /etc/modules-load.d/cake.conf

RUN mkdir -p /usr/share/gamemode && \
    echo '[general]' > /usr/share/gamemode/gamemode.ini && \
    echo 'renice=10' >> /usr/share/gamemode/gamemode.ini && \
    echo 'ioprio=0' >> /usr/share/gamemode/gamemode.ini

# ---------------------------------------------------------------------------
# 3. PACKAGES & REPOS
# ---------------------------------------------------------------------------
RUN curl -fsSL https://copr.fedorainfracloud.org/coprs/ilyaz/LACT/repo/fedora-$(rpm -E %fedora)/ilyaz-LACT.repo \
    -o /etc/yum.repos.d/ilyaz-LACT.repo

# TERRA FIX (Pragmatic approach)
RUN sed -i 's/gpgcheck=1/gpgcheck=0/' /etc/yum.repos.d/terra.repo || true && \
    sed -i 's/gpgcheck=1/gpgcheck=0/' /etc/yum.repos.d/terra-mesa.repo || true

RUN rpm-ostree install \
    lact \
    mangohud \
    goverlay \
    distribution-gpg-keys \
    && rm -rf /var/cache/rpms

# ScopeBuddy
RUN curl -fsSL "https://raw.githubusercontent.com/HikariKnight/ScopeBuddy/main/bin/scopebuddy" -o /usr/bin/scopebuddy && \
    chmod +x /usr/bin/scopebuddy && \
    ln -s /usr/bin/scopebuddy /usr/bin/scb

# ---------------------------------------------------------------------------
# 4. LACT HARDENING (Atomic-Safe & Sorted)
# ---------------------------------------------------------------------------
# A. Service Override (Wait for Udev)
RUN mkdir -p /etc/systemd/system/lactd.service.d && \
    echo '[Unit]' > /etc/systemd/system/lactd.service.d/override.conf && \
    echo 'After=systemd-udev-settle.service' >> /etc/systemd/system/lactd.service.d/override.conf && \
    echo 'Wants=systemd-udev-settle.service' >> /etc/systemd/system/lactd.service.d/override.conf

# B. Dynamic Config Script (Sorted & Apply-On-Startup)
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

# C. One-Shot Service to run the script
RUN echo '[Unit]' > /etc/systemd/system/lact-setup.service && \
    echo 'Description=Generate LACT Config for GPU' >> /etc/systemd/system/lact-setup.service && \
    echo 'After=systemd-udev-settle.service' >> /etc/systemd/system/lact-setup.service && \
    echo 'Before=lactd.service' >> /etc/systemd/system/lact-setup.service && \
    echo '[Service]' >> /etc/systemd/system/lact-setup.service && \
    echo 'Type=oneshot' >> /etc/systemd/system/lact-setup.service && \
    echo 'ExecStart=/usr/bin/setup-lact.sh' >> /etc/systemd/system/lact-setup.service && \
    echo '[Install]' >> /etc/systemd/system/lact-setup.service && \
    echo 'WantedBy=multi-user.target' >> /etc/systemd/system/lact-setup.service

# D. Enable Services (The Atomic Way)
RUN systemctl enable lactd.service && \
    systemctl enable lact-setup.service

# ---------------------------------------------------------------------------
# 5. NEXTDNS & PROTON-GE
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

COPY scripts/install-ge-proton.sh /tmp/install-ge-proton.sh
RUN chmod +x /tmp/install-ge-proton.sh && \
    /tmp/install-ge-proton.sh && \
    rm /tmp/install-ge-proton.sh

# ---------------------------------------------------------------------------
# 6. CLEANUP
# ---------------------------------------------------------------------------
RUN rm -rf /var/cache/rpms /var/cache/dnf