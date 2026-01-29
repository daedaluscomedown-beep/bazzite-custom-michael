# We use the base image defined in your recipe
FROM ghcr.io/ublue-os/bazzite-kde:stable

# 1. Copy your custom files (overlays files/usr -> /usr, files/etc -> /etc)
# This ensures your EDID firmware and undervolt service units are in place.
COPY files /

# 2. Copy your scripts so build.sh can run them
COPY scripts /tmp/scripts

# 3. Copy the main build script
COPY build_files/build.sh /tmp/build.sh

# 4. Run the build script
RUN chmod +x /tmp/build.sh && /tmp/build.sh

# 5. Cleanup temporary scripts
RUN rm -rf /tmp/scripts /tmp/build.sh