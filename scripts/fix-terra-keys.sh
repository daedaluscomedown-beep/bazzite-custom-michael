#!/bin/bash
echo "--- Fixing Terra GPG Keys for ISO Build ---"

# 1. Ensure the directory exists
install -d -m 0755 /etc/pki/rpm-gpg

# 2. Download the key to the EXACT path the repo config expects.
# The repo asks for 'RPM-GPG-KEY-terra43-mesa', so we save it as that.
curl -fsSL https://repo.terrapkg.com/keys/RPM-GPG-KEY-terra \
  -o /etc/pki/rpm-gpg/RPM-GPG-KEY-terra43-mesa

# 3. Import the key to the RPM database
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-terra43-mesa

# 4. SELinux cleanup (The "Extra Correct" Step)
restorecon -Rv /etc/pki/rpm-gpg || true