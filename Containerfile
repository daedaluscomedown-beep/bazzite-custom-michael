# ============================================================
# FINAL BOSS V3: BAZZITE 5800X3D + RDNA ULTRA-OPTIMIZED
# Focus: Deterministic, Immutable-Safe, Zero-Latency
# ============================================================

FROM ghcr.io/ublue-os/bazzite:latest

LABEL org.opencontainers.image.title="bazzite-final-boss"
LABEL org.opencontainers.image.description="Maximum Performance 5800X3D/RDNA Image"
LABEL org.opencontainers.image.authors="Michael O'Neill"

# ------------------------------------------------------------
# 1. REPOS (Manual Definition - No Network Failures)
# ------------------------------------------------------------
# We manually write the repo file instead of curling it. 
# We target Fedora 40 explicitly because it is stable and binary-compatible.
RUN printf '[copr:copr.fedorainfracloud.org:iguanadil:lact]\n\
name=Copr repo for lact owned by iguanadil\n\
baseurl=https://download.copr.fedorainfracloud.org/results/iguanadil/lact/fedora-40-$basearch/\n\
type=rpm-md\n\
skip_if_unavailable=True\n\
gpgcheck=1\n\
gpgkey=https://download.copr.fedorainfracloud.org/results/iguanadil/lact/pubkey.gpg\n\
repo_gpgcheck=0\n\
enabled=1\n' > /etc/yum.repos.d/lact.repo

# ------------------------------------------------------------
# 2. PACKAGES (Additions Only)
# ------------------------------------------------------------
# We do NOT remove power-profiles-daemon here to avoid build failures.
# We will mask it later (disable it) instead.
RUN rpm-ostree install \
    lact \
    gamemode \
    kernel-tools \
    btop \
    nvtop \
    git \
    curl \
    jq \
    distrobox \
    --idempotent \
    && rpm-ostree cleanup -m

# ------------------------------------------------------------
# 3. KERNEL & SCHEDULER TUNING (5800X3D Specific)
# ------------------------------------------------------------
RUN mkdir -p /etc/sysctl.d && \
    printf '%s\n' \
    "vm.swappiness=1" \
    "vm.dirty_ratio=10" \
    "vm.dirty_background_ratio=5" \
    "kernel.sched_autogroup_enabled=0" \
    "kernel.hung_task_timeout_secs=120" \
    "kernel.nmi_watchdog=0" \
    > /etc/sysctl.d/99-gaming-final.conf

# ------------------------------------------------------------
# 4. FORCE PERFORMANCE GOVERNOR (Kill PPD/Tuned)
# ------------------------------------------------------------
# 1. Mask the stock power daemons so they don't interfere
RUN systemctl mask power-profiles-daemon.service \
    tuned.service \
    tuned-ppd.service

# 2. Force 'performance' governor at boot using cpupower
RUN printf "[Unit]\nDescription=Force CPU Performance Governor\nAfter=multi-user.target\n\n[Service]\nType=oneshot\nExecStart=/usr/bin/cpupower frequency-set -g performance\nExecStart=/usr/bin/cpupower idle-set -D 0\nRemainAfterExit=yes\n\n[Install]\nWantedBy=multi-user.target\n" > /etc/systemd/system/force-performance.service
RUN systemctl enable force-performance.service

# ------------------------------------------------------------
# 5. GE-PROTON (Immutable-Safe Symlink Strategy)
# ------------------------------------------------------------
RUN mkdir -p /usr/share/steam/compatibilitytools.d && \
    ln -s /var/opt/ge-proton-latest /usr/share/steam/compatibilitytools.d/ge-proton-latest

# The Updater Script
RUN mkdir -p /usr/libexec && \
    printf '#!/usr/bin/env bash\n\
set -euo pipefail\n\
TARGET_DIR="/var/opt/ge-proton-latest"\n\
TMP_DIR="$(mktemp -d)"\n\
\n\
# Fetch latest URL\n\
LATEST_JSON="$(curl -fsSL https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest)"\n\
TARBALL_URL="$(echo "$LATEST_JSON" | grep browser_download_url | grep tar.gz | cut -d \" -f 4)"\n\
\n\
# Download & Extract\n\
mkdir -p "$TARGET_DIR"\n\
cd "$TMP_DIR"\n\
curl -fsSL "$TARBALL_URL" -o ge.tar.gz\n\
tar -xzf ge.tar.gz\n\
\n\
# Sync new files\n\
rm -rf "$TARGET_DIR"/*\n\
mv GE-Proton*/* "$TARGET_DIR"/\n\
\n\
# Clean up\n\
rm -rf "$TMP_DIR"\n\
sed -i "s/GE-Proton.*/ge-proton-latest/" "$TARGET_DIR/compatibilitytool.vdf" || true\n\
' > /usr/libexec/update-ge-proton.sh && \
    chmod +x /usr/libexec/update-ge-proton.sh

# Service & Timer
RUN printf "[Unit]\nDescription=Update GE-Proton\nAfter=network-online.target\nWants=network-online.target\n\n[Service]\nType=oneshot\nExecStart=/usr/libexec/update-ge-proton.sh\n" > /etc/systemd/system/ge-proton-update.service
RUN printf "[Unit]\nDescription=Daily GE-Proton Update\n\n[Timer]\nOnBootSec=10min\nOnUnitActiveSec=24h\nPersistent=true\n\n[Install]\nWantedBy=timers.target\n" > /etc/systemd/system/ge-proton-update.timer
RUN systemctl enable ge-proton-update.timer

# ------------------------------------------------------------
# 6. LACT OVERRIDE
# ------------------------------------------------------------
RUN mkdir -p /etc/systemd/system/lactd.service.d && \
    printf '[Unit]\nAfter=multi-user.target\nRequires=multi-user.target\n' > /etc/systemd/system/lactd.service.d/override.conf
RUN systemctl enable lactd.service

# ------------------------------------------------------------
# 7. FINAL CLEANUP
# ------------------------------------------------------------
RUN systemctl mask abrtd.service

CMD ["/sbin/init"]