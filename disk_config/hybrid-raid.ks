# ============================================================================
# BAZZITE BTRFS FOUNDATION (Single Drive Start)
# We install to Drive 1 (nvme0n1) only. Drive 2 is added post-boot.
# ============================================================================

lang en_US.UTF-8
keyboard us
timezone America/New_York --utc
network --bootproto=dhcp --device=link --activate
rootpw --plaintext changeme

# 1. Initialize the First Drive (Wipes nvme0n1 only)
zerombr
clearpart --all --initlabel --drives=nvme0n1

# ============================================================================
# PARTITIONING (Standard Fedora Atomic Layout)
# ============================================================================

# Boot Loaders (Required for UEFI/BIOS)
part /boot/efi --fstype=efi --size=600 --ondisk=nvme0n1
part /boot     --fstype=ext4 --size=1024 --ondisk=nvme0n1

# The BTRFS Pool (Takes all remaining space on Drive 1)
# Note: We do NOT touch nvme1n1 here. The setup script handles that later.
part btrfs.01 --fstype=btrfs --size=1 --grow --ondisk=nvme0n1

# Atomic Subvolumes (Critical for Bazzite/Silverblue)
# These map the BTRFS subvolumes to the OS structure.
btrfs /     --subvol --name=root btrfs.01
btrfs /home --subvol --name=home btrfs.01
btrfs /var  --subvol --name=var  btrfs.01

# Bootloader (Install on the first drive)
bootloader --location=mbr --boot-drive=nvme0n1

# ============================================================================
# THE PAYLOAD
# ============================================================================
# Pulls your custom image
bootc --source-imgref=ghcr.io/daedaluscomedown-beep/deconfliction:latest

reboot

# ============================================================================
# POST-INSTALL
# ============================================================================
%post
# No RAID tuning needed here yet.
# The 'setup-storage.sh' script in the image will handle
# adding the second drive and balancing the RAID on first boot.
echo "BTRFS Foundation Installed. Ready for Phase 2."
%end
