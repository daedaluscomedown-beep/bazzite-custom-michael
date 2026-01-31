# -----------------------------------------------------------------------------
# DECONFLICTION - Custom Bazzite Image
# Optimized for: AMD Ryzen 5800X3D + AMD Radeon
# Feedback Implementation: Atomic-Safe, Security-Conscious, Single-File Cache
# -----------------------------------------------------------------------------

ARG IMAGE_NAME="bazzite"
ARG IMAGE_VENDOR="ublue-os"
ARG IMAGE_TAG="stable"
FROM ghcr.io/${IMAGE_VENDOR}/${IMAGE_NAME}:${IMAGE_TAG}

# -----------------------------------------------------------------------------
# 1. GLOBAL PERFORMANCE VARIABLES
# -----------------------------------------------------------------------------
# Added 'MESA_SHADER_CACHE_SINGLE_FILE=1' per expert feedback for EXT4/XFS optimization
RUN echo 'MESA_SHADER_CACHE_MAX_SIZE=20G' >> /etc/environment && \
    echo 'MESA_SHADER_CACHE_DIR=/var/cache/mesa' >> /etc/environment && \
    echo 'RADV_PERFTEST=aco,sam' >> /etc/environment && \
    echo 'MESA_SHADER_CACHE_SINGLE_FILE=1' >> /etc/environment

# Create cache dir with open permissions
RUN mkdir -p /var/cache/mesa && chmod 1777 /var/cache/mesa

# -----------------------------------------------------------------------------
# 2. SYSTEM TUNING (Sysctl)
# -----------------------------------------------------------------------------
# Matches the "Golden Trio" for gaming stability
RUN tee /etc/sysctl.d/99-gaming.conf << 'EOF'
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.max_map_count=1048576
EOF

# -----------------------------------------------------------------------------
# 3. KERNEL ARGUMENTS
# -----------------------------------------------------------------------------
# REMOVED: mitigations=off (Moved to post-install choice for safety/Anti-Cheat)
# KEPT: amd_pstate=active (Essential for 5800X3D)
RUN rpm-ostree kargs \
    --append=nowatchdog \
    --append=amd_pstate=active

# -----------------------------------------------------------------------------
# 4. PACKAGES & SERVICES (LACT for AMD GPU)
# -----------------------------------------------------------------------------
# Installing LACT for GPU Fan Curves/Overclocking
# We use the COPR repo which is standard for Fedora/Bazzite
RUN wget https://copr.fedorainfracloud.org/coprs/lukenukem/lact/repo/fedora-41/lukenukem-lact-fedora-41.repo -O /etc/yum.repos.d/lukenukem-lact.repo && \
    rpm-ostree install lact

# Enable LACT globally (The "Atomic" way, so it survives updates)
RUN systemctl enable --global lactd.service

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# 5. CUSTOM SCRIPTS
# -----------------------------------------------------------------------------
COPY scripts/ /tmp/scripts/

# Ensure everything is executable (fixes potential git permission issues)
RUN chmod +x /tmp/scripts/*

# 1. RUN BUILD-TIME SCRIPTS
# We execute disable-terra.sh NOW so it prevents repo conflicts permanently.
# We check if it exists first to avoid build failure if you deleted it locally.
RUN if [ -f /tmp/scripts/disable-terra.sh ]; then /tmp/scripts/disable-terra.sh; fi

# 2. INSTALL RUNTIME SCRIPTS
# We move the runtime tools to /usr/bin so you can type them in the terminal
# We strictly move only what we need to avoid clutter.
RUN mv /tmp/scripts/install-ge-proton.sh /usr/bin/ && \
    mv /tmp/scripts/update-deconfliction.sh /usr/bin/ && \
    rm -rf /tmp/scripts

# -----------------------------------------------------------------------------
# 6. FINAL CLEANUP
# -----------------------------------------------------------------------------
RUN echo "✅ Deconfliction Image Build Complete."