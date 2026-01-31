# -----------------------------------------------------------------------------
# DECONFLICTION - Custom Bazzite Image
# Optimized for: AMD Ryzen 5800X3D + AMD Radeon + Samsung G5
# -----------------------------------------------------------------------------

ARG IMAGE_NAME="bazzite"
ARG IMAGE_VENDOR="ublue-os"
ARG IMAGE_TAG="stable"
FROM ghcr.io/${IMAGE_VENDOR}/${IMAGE_NAME}:${IMAGE_TAG}

# -----------------------------------------------------------------------------
# 1. GLOBAL PERFORMANCE VARIABLES
# -----------------------------------------------------------------------------
RUN echo 'MESA_SHADER_CACHE_MAX_SIZE=20G' >> /etc/environment && \
    echo 'MESA_SHADER_CACHE_DIR=/var/cache/mesa' >> /etc/environment && \
    echo 'RADV_PERFTEST=aco,sam' >> /etc/environment && \
    echo 'MESA_SHADER_CACHE_SINGLE_FILE=1' >> /etc/environment && \
    echo 'RADV_DEBUG=zerovram' >> /etc/environment

# Create cache dir with open permissions
RUN mkdir -p /var/cache/mesa && chmod 1777 /var/cache/mesa

# -----------------------------------------------------------------------------
# 2. DISABLE TERRA REPOS (CRITICAL FIX)
# -----------------------------------------------------------------------------
COPY scripts/disable-terra.sh /tmp/disable-terra.sh
RUN chmod +x /tmp/disable-terra.sh && \
    /tmp/disable-terra.sh && \
    rm /tmp/disable-terra.sh

# -----------------------------------------------------------------------------
# 3. SYSTEM TUNING (Safe Method)
# -----------------------------------------------------------------------------
RUN echo "vm.swappiness=10" > /etc/sysctl.d/99-gaming.conf && \
    echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.d/99-gaming.conf && \
    echo "vm.max_map_count=1048576" >> /etc/sysctl.d/99-gaming.conf

# -----------------------------------------------------------------------------
# 4. INSTALL CUSTOM FILES (EDID)
# -----------------------------------------------------------------------------
COPY files/usr/lib/firmware/edid/samsung_g5_custom.bin /usr/lib/firmware/edid/samsung_g5_custom.bin

# -----------------------------------------------------------------------------
# 5. PACKAGES (LACT)
# -----------------------------------------------------------------------------
# We install the package here, but enable the service in the post-install script
RUN dnf copr enable -y ilyaz/LACT && \
    rpm-ostree install lact

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