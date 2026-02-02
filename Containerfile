# -----------------------------------------------------------------------------
# DECONFLICTION - Custom Bazzite Image
# Optimized for: AMD Ryzen 5800X3D + AMD Radeon RX 9070 + Razer Raptor
# Audit Status: FINAL (NextDNS + Network + Stability + Anti-Lag 2)
# -----------------------------------------------------------------------------

ARG IMAGE_NAME="bazzite"
ARG IMAGE_VENDOR="ublue-os"
ARG IMAGE_TAG="stable"
FROM ghcr.io/${IMAGE_VENDOR}/${IMAGE_NAME}:${IMAGE_TAG}

# -----------------------------------------------------------------------------
# 1. GLOBAL PERFORMANCE VARIABLES (The "Golden Block")
# -----------------------------------------------------------------------------
# - AMD_VULKAN_ICD: Force RADV.
# - RADV_PERFTEST: gpl (Stutter Fix), sam (Smart Access Memory), video_decode.
# - ENABLE_LAYER_MESA_ANTI_LAG: Global enable for Anti-Lag 2.
# - VKD3D_CONFIG: no_upload_hvv (UE5/Div2 Stability).
# - MESA_SHADER_CACHE: 20GB Single File.
RUN echo 'AMD_VULKAN_ICD=radv' >> /etc/environment && \
    echo 'RADV_PERFTEST=gpl,sam,video_decode' >> /etc/environment && \
    echo 'ENABLE_LAYER_MESA_ANTI_LAG=1' >> /etc/environment && \
    echo 'VKD3D_CONFIG=no_upload_hvv' >> /etc/environment && \
    echo 'MESA_SHADER_CACHE_MAX_SIZE=20G' >> /etc/environment && \
    echo 'MESA_SHADER_CACHE_DIR=/var/cache/mesa' >> /etc/environment && \
    echo 'MESA_SHADER_CACHE_SINGLE_FILE=1' >> /etc/environment

# Create cache dir with open permissions
RUN mkdir -p /var/cache/mesa && chmod 1777 /var/cache/mesa

# -----------------------------------------------------------------------------
# 2. DISABLE TERRA REPOS (Dependency Safety)
# -----------------------------------------------------------------------------
COPY scripts/disable-terra.sh /tmp/disable-terra.sh
RUN chmod +x /tmp/disable-terra.sh && \
    /tmp/disable-terra.sh && \
    rm /tmp/disable-terra.sh

# -----------------------------------------------------------------------------
# 3. SYSTEM TUNING (X3D + Network Optimized)
# -----------------------------------------------------------------------------
# - swappiness=1: 5800X3D wants pages in RAM.
# - net.ipv4.tcp_congestion_control=bbr: Low Latency Network.
# - net.core.default_qdisc=cake: Bufferbloat killer.
RUN echo "vm.swappiness=1" > /etc/sysctl.d/99-gaming.conf && \
    echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.d/99-gaming.conf && \
    echo "vm.max_map_count=1048576" >> /etc/sysctl.d/99-gaming.conf && \
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.d/99-gaming.conf && \
    echo "net.core.default_qdisc=cake" >> /etc/sysctl.d/99-gaming.conf

# -----------------------------------------------------------------------------
# 4. GAMEMODE PRIORITY (Focus)
# -----------------------------------------------------------------------------
# Force games to have higher CPU priority than background apps
RUN mkdir -p /etc/gamemode.ini.d && \
    echo "[general]" > /etc/gamemode.ini && \
    echo "renice=10" >> /etc/gamemode.ini && \
    echo "ioprio=0" >> /etc/gamemode.ini

# -----------------------------------------------------------------------------
# 5. PACKAGES (LACT & NEXTDNS)
# -----------------------------------------------------------------------------
# Install LACT
RUN dnf copr enable -y ilyaz/LACT && \
    rpm-ostree install lact

# Install NextDNS Binary (Downloaded to /usr/bin so it's baked in)
# We pull the latest stable binary directly to bypass Read-Only limits later
RUN curl -Lo /tmp/nextdns.tar.gz https://github.com/nextdns/nextdns/releases/download/v1.43.5/nextdns_1.43.5_linux_amd64.tar.gz && \
    tar -xzf /tmp/nextdns.tar.gz -C /usr/bin nextdns && \
    chmod +x /usr/bin/nextdns && \
    rm /tmp/nextdns.tar.gz

# -----------------------------------------------------------------------------
# 6. RUNTIME SCRIPTS
# -----------------------------------------------------------------------------
COPY scripts/ /tmp/scripts/
RUN chmod +x /tmp/scripts/* && \
    mv /tmp/scripts/install-ge-proton.sh /usr/bin/ && \
    mv /tmp/scripts/update-deconfliction.sh /usr/bin/ && \
    rm -rf /tmp/scripts

# -----------------------------------------------------------------------------
# 7. FINAL CLEANUP
# -----------------------------------------------------------------------------
RUN echo "✅ Deconfliction Image Build Complete."