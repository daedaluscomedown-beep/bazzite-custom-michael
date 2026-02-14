# ============================================================
# GAMING PERFORMANCE IMAGE
# Target: Bazzite (bootc / ostree)
# Focus: Stability + Performance
# Hardware: Ryzen 7 5800X3D + RDNA GPU
# ============================================================

FROM ghcr.io/ublue-os/bazzite:latest

LABEL org.opencontainers.image.title="bazzite-gaming-michael"
LABEL org.opencontainers.image.description="Stable high-performance Bazzite gaming image"
LABEL org.opencontainers.image.authors="Michael O'Neill"

# ------------------------------------------------------------
# Core Tools (Fedora native only — no COPR risk)
# ------------------------------------------------------------
RUN rpm-ostree install \
    gamemode \
    tuned \
    tuned-ppd \
    btop \
    nvtop \
    git \
    curl \
    wget \
    jq \
    distrobox \
    podman \
    power-profiles-daemon \
    --idempotent \
    && rpm-ostree cleanup -m

# ------------------------------------------------------------
# Gaming sysctl tuning (Safe values)
# ------------------------------------------------------------
RUN mkdir -p /etc/sysctl.d && \
    printf '%s\n' \
    "vm.swappiness=10" \
    "vm.dirty_ratio=10" \
    "vm.dirty_background_ratio=5" \
    "kernel.sched_autogroup_enabled=0" \
    > /etc/sysctl.d/99-gaming-performance.conf

# ------------------------------------------------------------
# Enable tuned performance profile
# ------------------------------------------------------------
RUN systemctl enable tuned.service

CMD ["/sbin/init"]
