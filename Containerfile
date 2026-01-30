# We use the base image defined in your recipe
FROM ghcr.io/ublue-os/bazzite:stable

# 1. Copy your custom files (overlays files/usr -> /usr, files/etc -> /etc)
COPY files /

# --- NEW SECTION STARTS HERE ---
# Add GE-Proton Auto-Installer
COPY scripts/install-ge-proton.sh /usr/bin/update-proton
RUN chmod +x /usr/bin/update-proton
# --- NEW SECTION ENDS HERE ---

# 2. Copy your scripts so build.sh can run them
COPY scripts /tmp/scripts

# 3. Copy the main build script
COPY build_files/build.sh /tmp/build.sh

# 4. Run the build script
RUN chmod +x /tmp/build.sh && /tmp/build.sh

# 5. Cleanup temporary scripts
RUN rm -rf /tmp/scripts /tmp/build.sh