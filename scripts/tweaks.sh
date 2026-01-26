#!/bin/bash
echo "--- Final System Tweaks ---"

# 1. Ensure MIME database sees Chrome as default
update-mime-database /usr/share/mime

# 2. Enable the Undervolt Service for All Users
systemctl --global enable undervolt.service