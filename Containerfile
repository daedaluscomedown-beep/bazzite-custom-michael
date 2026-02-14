FROM ghcr.io/ublue-os/bazzite:latest

# ===============================
# Performance + Stability Packages
# ===============================

RUN rpm-ostree install \
    lact \
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
    --idempotent

# ===============================
# Remove power-profiles-daemon (conflicts with tuned)
# ===============================

RUN ln -sf /dev/null /etc/systemd/system/power-profiles-daemon.service

# ===============================
# Enable tuned (performance profile)
# ===============================

RUN mkdir -p /etc/systemd/system/multi-user.target.wants && \
    ln -sf /usr/lib/systemd/system/tuned.service \
    /etc/systemd/system/multi-user.target.wants/tuned.service

# Set tuned profile to throughput-performance (best for 5800X3D)
RUN mkdir -p /etc/tuned && \
    echo "throughput-performance" > /etc/tuned/active_profile

# ===============================
# Enable LACT daemon
# ===============================

RUN ln -sf /usr/lib/systemd/system/lactd.service \
    /etc/systemd/system/multi-user.target.wants/lactd.service

# ===============================
# GE-Proton Auto Update Script
# ===============================

COPY ge-proton-update.sh /usr/local/bin/ge-proton-update.sh
RUN chmod +x /usr/local/bin/ge-proton-update.sh

COPY ge-proton-update.service /etc/systemd/system/ge-proton-update.service
COPY ge-proton-update.timer /etc/systemd/system/ge-proton-update.timer

RUN mkdir -p /etc/systemd/system/timers.target.wants && \
    ln -sf /etc/systemd/system/ge-proton-update.timer \
    /etc/systemd/system/timers.target.wants/ge-proton-update.timer

# ===============================
# Sysctl Performance Tweaks
# ===============================

COPY 99-gaming-performance.conf /etc/sysctl.d/99-gaming-performance.conf

# ===============================
# ZRAM tuning (better for 32GB RAM)
# ===============================

RUN mkdir -p /etc/systemd/zram-generator.conf.d && \
    echo -e "[zram0]\nzram-size = ram / 2\ncompression-algorithm = zstd" \
    > /etc/systemd/zram-generator.conf.d/custom.conf

# ===============================
# Finish
# ===============================

RUN ostree container commit
