#!/bin/bash
echo "--- Disabling Terra Repositories (Fixes ISO Build) ---"
# We disable the repo during the build to prevent GPG errors.
# You will enable 'terra' manually after installation for your Mesa drivers.

for repo_file in $(find /etc/yum.repos.d /usr/etc/yum.repos.d -name "*terra*.repo" 2>/dev/null); do
    echo "Disabling repo: $repo_file"
    sed -i 's/enabled=1/enabled=0/g' "$repo_file"
done