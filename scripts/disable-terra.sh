#!/bin/bash
set -ouex pipefail

# Loop through any repo file that contains "terra" in the name
for repo in /etc/yum.repos.d/*terra*.repo; do
    # Check if the file actually exists before trying to modify it
    if [ -f "$repo" ]; then
        echo "Disabling repo: $repo"
        # Use sed to swap enabled=1 to enabled=0
        sed -i 's/enabled=1/enabled=0/g' "$repo"
    fi
done