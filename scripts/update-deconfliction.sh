#!/bin/bash
# System Update Script for Deconfliction OS
echo "🚀 Starting Deconfliction Update..."
echo "-----------------------------------"

# 1. Update Flatpaks (Background apps)
echo "📦 Updating Applications..."
flatpak update -y

# 2. Run the Proton Updater (The script we just fixed)
if command -v install-ge-proton.sh &> /dev/null; then
    install-ge-proton.sh
else
    echo "⚠️  Proton updater not found."
fi

# 3. System Update (The OS itself)
# We pipe 'Q' to auto-quit the prompt so it doesn't hang
echo "💿 Updating System..."
echo "Q" | /usr/bin/ujust update

echo "-----------------------------------"
echo "✅ Maintenance Complete. You may need to reboot."
read -p "Press Enter to exit..."