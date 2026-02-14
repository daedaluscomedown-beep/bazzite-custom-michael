# ============================================================
# FINAL BOSS: BAZZITE 5800X3D + RDNA ULTRA-OPTIMIZED
# Focus: Deterministic, Immutable-Safe, Zero-Latency
# ============================================================

FROM ghcr.io/ublue-os/bazzite:latest

LABEL org.opencontainers.image.title="bazzite-final-boss"
LABEL org.opencontainers.image.description="Maximum Performance 5800X3D/RDNA Image"
LABEL org.opencontainers.image.authors="Michael O'Neill"

# ------------------------------------------------------------
# 1. REPOS (Pinned for Stability)
# ------------------------------------------------------------
# Pinning to Fedora 41 (Current Bazzite base) to prevent macro failures
RUN wget -O /etc/yum.repos.d/lact.repo \
    https://copr.fedorainfracloud.org/coprs/iguanadil/lact/repo/fedora-41/iguanadil-lact-fedora-41.repo

# ------------------------------------------------------------
# 2. PACKAGES (Lean & Mean)
# ------------------------------------------------------------
# We REMOVE power-profiles-daemon and tuned. They add latency.
# We ADD kernel-tools (for raw cpupower control).
RUN rpm-ostree override remove \
    power-profiles-daemon \
    tuned \
    tuned-ppd \
    --install lact \
    --install gamemode \
    --install kernel-tools \
    --install btop \
    --install nvtop \
    --install git \
    --install curl \
    --install jq \
    --install distrobox \
    && rpm-ostree cleanup -m

# ------------------------------------------------------------
# 3. KERNEL & SCHEDULER TUNING (5800X3D Specific)
# ------------------------------------------------------------
# vm.swappiness=1:        Only swap if absolutely critical (Keep game in RAM)
# sched_autogroup=0:      Stop kernel from grouping tasks; let GameMode handle priority
# hung_task_timeout=120:  Prevent RDNA 4 reset on heavy shader compiles
# dirty_ratio=10:         Write to disk sooner to prevent massive I/O lag spikes
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
# 4. FORCE PERFORMANCE GOVERNOR (No Daemons)
# ------------------------------------------------------------
# Instead of PPD/Tuned, we force the CPU to max frequency at boot.
# This eliminates the 100-200ms latency of "waking up" a core.
RUN printf "[Unit]\nDescription=Force CPU Performance Governor\nAfter=multi-user.target\n\n[Service]\nType=oneshot\nExecStart=/usr/bin/cpupower frequency-set -g performance\nExecStart=/usr/bin/cpupower idle-set -D 0\nRemainAfterExit=yes\n\n[Install]\nWantedBy=multi-user.target\n" > /etc/systemd/system/force-performance.service

RUN systemctl enable force-performance.service

# ------------------------------------------------------------
# 5. GE-PROTON (Immutable-Safe Symlink Strategy)
# ------------------------------------------------------------
# 1. Create a mutable directory in /var (where we download to)
# 2. Symlink it to /usr (where Steam looks)
# 3. Steam sees "ge-proton-latest" and follows the link to the actual files
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
# Nuke old files and sync new ones (rsync-style logic with mv)\n\
rm -rf "$TARGET_DIR"/*\n\
mv GE-Proton*/* "$TARGET_DIR"/\n\
\n\
# Clean up\n\
rm -rf "$TMP_DIR"\n\
# Create VDF metadata so Steam recognizes it generically\n\
# (Optional: The extracted tar usually has this, but this ensures the name matches)\n\
sed -i "s/GE-Proton.*/ge-proton-latest/" "$TARGET_DIR/compatibilitytool.vdf" || true\n\
' > /usr/libexec/update-ge-proton.sh && \
    chmod +x /usr/libexec/update-ge-proton.sh

# Service & Timer
RUN printf "[Unit]\nDescription=Update GE-Proton\nAfter=network-online.target\nWants=network-online.target\n\n[Service]\nType=oneshot\nExecStart=/usr/libexec/update-ge-proton.sh\n" > /etc/systemd/system/ge-proton-update.service
RUN printf "[Unit]\nDescription=Daily GE-Proton Update\n\n[Timer]\nOnBootSec=10min\nOnUnitActiveSec=24h\nPersistent=true\n\n[Install]\nWantedBy=timers.target\n" > /etc/systemd/system/ge-proton-update.timer
RUN systemctl enable ge-proton-update.timer

# ------------------------------------------------------------
# 6. LACT OVERRIDE (The Right Way)
# ------------------------------------------------------------
# No sed. Use drop-in config.
RUN mkdir -p /etc/systemd/system/lactd.service.d && \
    printf '[Unit]\nAfter=multi-user.target\nRequires=multi-user.target\n' > /etc/systemd/system/lactd.service.d/override.conf

RUN systemctl enable lactd.service

# ------------------------------------------------------------
# 7. FINAL CLEANUP
# ------------------------------------------------------------
RUN systemctl mask abrtd.service

CMD ["/sbin/init"]