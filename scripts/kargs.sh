#!/bin/bash
echo "--- Applying Michael's Kernel Arguments ---"

# 1. 5800X3D Stutter Fix (Split Lock Disable)
rpm-ostree kargs --append-if-missing="split_lock_detect=off"

# 2. RX 9070 Unlock (Voltage Control)
rpm-ostree kargs --append-if-missing="amdgpu.ppfeaturemask=0xffffffff"

# 3. Samsung G5 EDID Override (DISABLED FOR DAY 1)
# We comment this out because we haven't generated the .bin file yet.
# Once you dump the EDID on the new OS, add the file to the repo and uncomment this.
# rpm-ostree kargs --append-if-missing="drm.edid_firmware=DP-3:edid/samsung_g5_custom.bin"

# 4. Force Connector Status (Optional - Keep enabled if you want)
# Ensures DP-3 is enabled immediately.
rpm-ostree kargs --append-if-missing="video=DP-3:e"