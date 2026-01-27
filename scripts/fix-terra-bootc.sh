#!/bin/bash
echo "--- Fixing Terra Config for Bootc ISO Build ---"

# 1. Create the directory in /usr/etc (Visible to bootc builder)
install -d -m 0755 /usr/etc/pki/rpm-gpg

# 2. Download the key to /usr/etc
echo "Downloading Terra key to /usr/etc/pki/rpm-gpg..."
curl -fsSL https://repo.terrapkg.com/keys/RPM-GPG-KEY-terra \
  -o /usr/etc/pki/rpm-gpg/RPM-GPG-KEY-terra43-mesa

# 3. Patch the Repo Files to look in /usr/etc
# This is the critical step: changing the path inside the repo file.
echo "Patching Terra repo files to reference /usr/etc..."
# Check both standard locations just to be safe
for repo_file in $(find /etc/yum.repos.d /usr/etc/yum.repos.d -name "*terra*.repo" 2>/dev/null); do
    echo "Patching: $repo_file"
    sed -i 's|file:///etc/pki/rpm-gpg|file:///usr/etc/pki/rpm-gpg|g' "$repo_file"
done

# 4. Import key to RPM DB (Standard practice)
rpm --import /usr/etc/pki/rpm-gpg/RPM-GPG-KEY-terra43-mesa