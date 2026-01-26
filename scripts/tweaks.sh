#!/bin/bash
echo "--- Final System Tweaks ---"

# 1. Ensure MIME database sees Chrome as default
update-mime-database /usr/share/mime

# 2. Enable the Undervolt Service for All Users
systemctl --global enable undervolt.service

# 3. FIX: NUCLEAR OPTION for Terra Repository
# We are deleting the line that points to the missing key entirely.
echo "Nuking broken Terra key reference..."
find /etc/yum.repos.d/ -name "*.repo" -print0 | xargs -0 sed -i '/gpgkey=.*RPM-GPG-KEY-terra43-mesa/d'

# 4. Double Tap: Force GPG Check OFF for that repo just in case
find /etc/yum.repos.d/ -name "*.repo" -print0 | xargs -0 sed -i '/\[terra-mesa\]/,/^$/s/gpgcheck=1/gpgcheck=0/'