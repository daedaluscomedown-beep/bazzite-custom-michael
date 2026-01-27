#!/bin/bash
echo "--- Disabling Terra Repositories (Fixes ISO Build) ---"
# We modify the repo file directly. The builder MUST respect this.
# You will run 'ujust enable-terra' after install to get your drivers back.

for repo_file in $(find /etc/yum.repos.d /usr/etc/yum.repos.d -name "*terra*.repo" 2>/dev/null); do
    echo "Disabling repo: $repo_file"
    sed -i 's/enabled=1/enabled=0/g' "$repo_file"
done