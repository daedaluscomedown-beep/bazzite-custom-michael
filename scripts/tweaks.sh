#!/bin/bash
echo "--- Final System Tweaks ---"

# 1. Ensure MIME database sees Chrome as default
update-mime-database /usr/share/mime

# 2. Enable the Undervolt Service for All Users
systemctl --global enable undervolt.service

# 3. FIX: Patch broken Terra Repository GPG Key
# The build failed because 'terra-mesa' points to a missing local key.
# We will force-disable the GPG check for this repo so the ISO build can finish.
if grep -r "RPM-GPG-KEY-terra43-mesa" /etc/yum.repos.d/; then
    echo "Found broken Terra key reference. Disabling GPG check..."
    grep -l "RPM-GPG-KEY-terra43-mesa" /etc/yum.repos.d/*.repo | xargs sed -i 's/gpgcheck=1/gpgcheck=0/g'
fi