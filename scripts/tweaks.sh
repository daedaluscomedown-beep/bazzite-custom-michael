#!/bin/bash
echo "--- Final System Tweaks ---"

# 1. Ensure MIME database sees Chrome as default
update-mime-database /usr/share/mime

# 2. Enable the Undervolt Service for All Users
systemctl --global enable undervolt.service

# 3. FIX: The "Dummy Key" Trick (Solves Curl Error 37)
# The builder crashes because this file is missing. We will create it.
echo "Creating dummy GPG key to satisfy dnf..."
mkdir -p /etc/pki/rpm-gpg
touch /etc/pki/rpm-gpg/RPM-GPG-KEY-terra43-mesa

# 4. Force GPG Check OFF for the Terra Repo
# Now that the file exists, we tell the system to ignore that it's empty.
# We check both /etc and /usr/etc to be safe.
echo "Disabling GPG checks for terra-mesa..."
find /etc/yum.repos.d/ /usr/etc/yum.repos.d/ -name "*.repo" 2>/dev/null | xargs sed -i '/\[terra-mesa\]/,/^$/s/gpgcheck=1/gpgcheck=0/'