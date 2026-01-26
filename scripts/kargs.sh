#!/bin/bash
echo "--- Applying Michael's Kernel Arguments ---"

# 1. 5800X3D Stutter Fix
rpm-ostree kargs --append-if-missing="split_lock_detect=off"

# 2. RX 9070 Unlock (Voltage Control)
rpm-ostree kargs --append-if-missing="amdgpu.ppfeaturemask=0xffffffff"

# 3. Samsung G5 EDID Override (DP-3 Specific)
# Forces the kernel to use your custom EDID on the 3rd DisplayPort.
rpm-ostree kargs --append-if-missing="drm.edid_firmware=DP-3:edid/samsung_g5_custom.bin"

# 4. Force Connector Status
# Ensures DP-3 is enabled immediately.
rpm-ostree kargs --append-if-missing="video=DP-3:e"