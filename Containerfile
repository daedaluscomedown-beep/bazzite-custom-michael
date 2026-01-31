# -----------------------------------------------------------------------------
# DECONFLICTION - Custom Bazzite Image
# Optimized for: AMD Ryzen 5800X3D + AMD Radeon + Samsung G5
# Includes: Atomic-Safe Tweaks, Security Awareness, and Port-Agnostic Monitor Fix
# -----------------------------------------------------------------------------

ARG IMAGE_NAME="bazzite"
ARG IMAGE_VENDOR="ublue-os"
ARG IMAGE_TAG="stable"
FROM ghcr.io/${IMAGE_VENDOR}/${IMAGE_NAME}:${IMAGE_TAG}

# -----------------------------------------------------------------------------
# 1. GLOBAL PERFORMANCE VARIABLES
# -----------------------------------------------------------------------------
# - MESA_SHADER_CACHE_SINGLE_FILE=1: Optimizes cache for filesystem speed
# - RADV_DEBUG=zerovram: Fixes stutter/crashes in UE5 games (Gray Zone Warfare)
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
# We MUST do this before installing packages to prevent GPG/Dependency errors
COPY scripts/disable-terra.sh /tmp/disable-terra.sh
RUN chmod +x /tmp/disable-terra.sh && \
    /tmp/disable-terra.sh && \
    rm /tmp/disable-terra.sh

# -----------------------------------------------------------------------------
# 3. SYSTEM TUNING (Sysctl)
# -----------------------------------------------------------------------------
# FIXED: Replaced 'heredoc' with printf to prevent buildah syntax errors
RUN printf "vm.swappiness=10\nvm.vfs_cache_pressure=50\nvm.max_map_count=1048576\n" > /etc/sysctl.d/99-gaming.conf

# -----------------------------------------------------------------------------
# 4. INSTALL CUSTOM FILES (EDID)
# -----------------------------------------------------------------------------
# We copy the custom monitor firmware from your repo to the system firmware folder
COPY files/usr/lib/firmware/edid/samsung_g5_custom.bin /usr/lib/firmware/edid/samsung_g5_custom.bin

# -----------------------------------------------------------------------------
# 5. KERNEL ARGUMENTS
# -----------------------------------------------------------------------------
# - amd_pstate=active: Essential for 5800X3D boosting
# - amdgpu.ppfeaturemask=0xffffffff: Unlocks Overclocking/Fan control in LACT
# - split_lock_detect=off: Prevents micro-stutters
# - drm.edid_firmware: Forces custom EDID on ALL DisplayPorts (Shotgun Method)
RUN rpm-ostree kargs \
    --append-if-missing=nowatchdog \
    --append-if-missing=amd_pstate=active \
    --append-if-missing=split_lock_detect=off \
    --append-if-missing=amdgpu.ppfeaturemask=0xffffffff \
    --append-if-missing=drm.edid_firmware=DP-1:edid/samsung_g5_custom.bin \
    --append-if-missing=drm.edid_firmware=DP-2:edid/samsung_g5_custom.bin \
    --append-if-missing=drm.edid_firmware=DP-3:edid/samsung_g5_custom.bin

# -----------------------------------------------------------------------------
# 6. PACKAGES & SERVICES (LACT)
# -----------------------------------------------------------------------------
# We use 'dnf copr' now as it handles GPG keys better than wget
RUN dnf copr enable -y ilyaz/LACT && \
    rpm-ostree install lact && \
    systemctl enable --global lactd.service

# -----------------------------------------------------------------------------
# 7. RUNTIME SCRIPTS
# -----------------------------------------------------------------------------
COPY scripts/ /tmp/scripts/
RUN chmod +x /tmp/scripts/* && \
    mv /tmp/scripts/install-ge-proton.sh /usr/bin/ && \
    mv /tmp/scripts/update-deconfliction.sh /usr/bin/ && \
    rm -rf /tmp/scripts

# -----------------------------------------------------------------------------
# 8. FINAL CLEANUP
# -----------------------------------------------------------------------------
RUN echo "✅ Deconfliction Image Build Complete."