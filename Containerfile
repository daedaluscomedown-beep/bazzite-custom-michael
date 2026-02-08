FROM ghcr.io/ublue-os/bazzite:stable

# ---------------------------------------------------------------------------
# 1. PLATINUM PERFORMANCE TUNING (/usr/etc/environment)
# ---------------------------------------------------------------------------
RUN mkdir -p /usr/etc && \
    cat <<'EOF' >> /usr/etc/environment
# --- AMD GPU & RADV Tuning ---
AMD_VULKAN_ICD=radv
RADV_PERFTEST=gpl,sam,video_decode,nggc,rt
RADV_RT_PIPELINE_CACHE=1
ENABLE_LAYER_MESA_ANTI_LAG=1
VKD3D_CONFIG=no_upload_hvv

# --- Steam & Proton Tuning ---
PROTON_USE_NTSYNC=1
# Changed to 'auto' per audit to prevent blur on mixed-DPI setups
STEAM_FORCE_DESKTOPUI_SCALING=auto

# --- Mesa Cache (Persistent & Semantically Correct) ---
MESA_SHADER_CACHE_MAX_SIZE=20G
MESA_SHADER_CACHE_DIR=/var/lib/mesa
MESA_SHADER_CACHE_SINGLE_FILE=1
EOF

# Ensure the cache directory exists
RUN mkdir -p /var/lib/mesa && chmod 1777 /var/lib/mesa

# ---------------------------------------------------------------------------
# 2. SYSCTL TUNING (Latency & Safety)
# ---------------------------------------------------------------------------
RUN mkdir -p /usr/lib/sysctl.d && \
    cat <<EOF > /usr/lib/sysctl.d/99-gaming.conf
vm.swappiness=1
vm.vfs_cache_pressure=50
vm.max_map_count=262144
net.ipv4.tcp_congestion_control=bbr
net.core.default_qdisc=cake
EOF

# ---------------------------------------------------------------------------
# 3. GAMEMODE CONFIGURATION
# ---------------------------------------------------------------------------
RUN mkdir -p /usr/share/gamemode && \
    cat <<EOF > /usr/share/gamemode/gamemode.ini
[general]
renice=10
ioprio=0
EOF

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

# C. Enable LACT Service (Immutable Symlink Method)
RUN ln -s /usr/lib/systemd/system/lactd.service \
    /usr/lib/systemd/system/multi-user.target.wants/lactd.service

# ---------------------------------------------------------------------------
# 5. NEXTDNS (Hardened Service)
# NOTE: Updates to NextDNS occur via image rebuilds, not runtime auto-update.
# ---------------------------------------------------------------------------
# Fetch binary
RUN curl -fsSL "https://github.com/nextdns/nextdns/releases/latest/download/nextdns_linux_amd64" -o /usr/bin/nextdns && \
    chmod +x /usr/bin/nextdns

# Config
RUN mkdir -p /etc/nextdns && \
    cat <<EOF > /etc/nextdns/config
auto-activate true
cache-size 10MB
timeout 5s
EOF

# Service
RUN cat <<EOF > /etc/systemd/system/nextdns.service
[Unit]
Description=NextDNS DNS53 to DoH proxy
ConditionFileNotEmpty=/etc/nextdns/config
After=network-online.target
Wants=network-online.target

[Service]
# Removed explicit -config flag (redundant)
ExecStart=/usr/bin/nextdns run
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Enable NextDNS Service (Immutable Symlink Method)
RUN ln -s /etc/systemd/system/nextdns.service \
    /etc/systemd/system/multi-user.target.wants/nextdns.service

# ---------------------------------------------------------------------------
# 6. PROTON-GE (System-Wide)
# NOTE: Updates to Proton-GE occur via image rebuilds.
# ---------------------------------------------------------------------------
COPY scripts/install-ge-proton.sh /tmp/install-ge-proton.sh
RUN chmod +x /tmp/install-ge-proton.sh && \
    /tmp/install-ge-proton.sh && \
    rm /tmp/install-ge-proton.sh

# ---------------------------------------------------------------------------
# 7. CLEANUP
# ---------------------------------------------------------------------------
RUN rm -rf /var/cache/rpms /var/cache/dnf