#!/bin/bash
# Optimized for Bazzite / Flatpak Steam
echo "🔍 Syncing Flathub Repository..."
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "🎮 Updating GE-Proton (Flatpak)..."
# This handles the install and the update in one go
flatpak install --user -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE

# --- CLEANUP ---
# Now that the Flatpak version works, we remove the manual folders
# to prevent Steam from getting confused again.
if [ -d "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d" ]; then
    echo "🧹 Cleaning up manual Proton attempts..."
    rm -rf "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d/GE-Proton"*
fi

echo "✨ GE-Proton is now fully managed by the Flatpak system!"