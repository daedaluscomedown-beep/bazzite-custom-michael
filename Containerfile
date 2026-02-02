# -----------------------------------------------------------------------------
# DECONFLICTION - Custom Bazzite Image
# Optimized for: AMD Ryzen 5800X3D + AMD Radeon RX 9070
# Audit Status: PASSED (Razer Monitor Updated)
# -----------------------------------------------------------------------------

ARG IMAGE_NAME="bazzite"
ARG IMAGE_VENDOR="ublue-os"
ARG IMAGE_TAG="stable"
FROM ghcr.io/${IMAGE_VENDOR}/${IMAGE_NAME}:${IMAGE_TAG}

# -----------------------------------------------------------------------------
# 1. GLOBAL PERFORMANCE VARIABLES
# -----------------------------------------------------------------------------
RUN echo 'AMD_VULKAN_ICD=radv' >> /etc/environment && \
    echo 'RADV_PERFTEST=gpl,sam,video_decode' >> /etc/environment && \
    echo 'ENABLE_LAYER_MESA_ANTI_LAG=1' >> /etc/environment && \
    echo 'VKD3D_CONFIG=no_upload_hvv' >> /etc/environment && \
    echo 'MESA_SHADER_CACHE_MAX_SIZE=20G' >> /etc/environment && \
    echo 'MESA_SHADER_CACHE_DIR=/var/cache/mesa' >> /etc/environment && \
    echo 'MESA_SHADER_CACHE_SINGLE_FILE=1' >> /etc/environment

RUN mkdir -p /var/cache/mesa && chmod 1777 /var/cache/mesa

# -----------------------------------------------------------------------------
# 2. DISABLE TERRA REPOS
# -----------------------------------------------------------------------------
COPY scripts/disable-terra.sh /tmp/disable-terra.sh
RUN chmod +x /tmp/disable-terra.sh && \
    /tmp/disable-terra.sh && \
    rm /tmp/disable-terra.sh

# -----------------------------------------------------------------------------
# 3. SYSTEM TUNING (X3D Optimized)
# -----------------------------------------------------------------------------
RUN echo "vm.swappiness=1" > /etc/sysctl.d/99-gaming.conf && \
    echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.d/99-gaming.conf && \
    echo "vm.max_map_count=1048576" >> /etc/sysctl.d/99-gaming.conf

# -----------------------------------------------------------------------------
# 4. PACKAGES (LACT)
# -----------------------------------------------------------------------------
RUN dnf copr enable -y ilyaz/LACT && \
    rpm-ostree install lact

# -----------------------------------------------------------------------------
# 5. RUNTIME SCRIPTS
# -----------------------------------------------------------------------------
COPY scripts/ /tmp/scripts/
RUN chmod +x /tmp/scripts/* && \
    mv /tmp/scripts/install-ge-proton.sh /usr/bin/ && \
    mv /tmp/scripts/update-deconfliction.sh /usr/bin/ && \
    rm -rf /tmp/scripts

# -----------------------------------------------------------------------------
# 6. FINAL CLEANUP
# -----------------------------------------------------------------------------
RUN echo "✅ Deconfliction Image Build Complete."