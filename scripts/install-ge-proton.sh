#!/bin/bash
# Optimized for Bazzite / Flatpak Steam
# This script ensures GE-Proton is managed via the Flatpak system

echo "🔍 Syncing Flathub Repository..."
# Ensure the remote exists so the script never fails
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "🎮 Updating GE-Proton (Flatpak)..."
# This installs it if missing OR updates it if a new version is out
flatpak install --user -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE

# --- CLEANUP OF OLD MANUAL INSTALLS ---
# This removes the manual folders that weren't showing up, 
# preventing them from cluttering your Steam menu.
if [ -d "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d" ]; then
    echo "🧹 Cleaning up old manual Proton folders..."
    rm -rf "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d/GE-Proton"*
fi

echo "✨ GE-Proton is now managed by Flatpak!"
echo "👉 Note: Restart Steam to see 'GE-Proton (Flatpak)' in your settings."