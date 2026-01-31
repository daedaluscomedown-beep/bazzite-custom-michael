#!/bin/bash
echo "🔧 Applying Kernel Arguments for 5800X3D + Samsung G5..."

rpm-ostree kargs \
    --append-if-missing=nowatchdog \
    --append-if-missing=amd_pstate=active \
    --append-if-missing=split_lock_detect=off \
    --append-if-missing=amdgpu.ppfeaturemask=0xffffffff \
    --append-if-missing=drm.edid_firmware=DP-1:edid/samsung_g5_custom.bin \
    --append-if-missing=drm.edid_firmware=DP-2:edid/samsung_g5_custom.bin \
    --append-if-missing=drm.edid_firmware=DP-3:edid/samsung_g5_custom.bin

echo "✅ Success! Please reboot to activate."