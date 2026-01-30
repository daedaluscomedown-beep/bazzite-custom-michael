#!/bin/bash
# Script to auto-download the latest GE-Proton

STEAM_DIR="$HOME/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d"
API_URL="https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest"

echo "🔍 Checking for latest GE-Proton..."

# 1. Create directory if missing
mkdir -p "$STEAM_DIR"

# 2. Get the download URL for the .tar.gz file
DOWNLOAD_URL=$(curl -s $API_URL | grep "browser_download_url" | grep ".tar.gz" | head -n 1 | cut -d '"' -f 4)
FILENAME=$(basename "$DOWNLOAD_URL")
FOLDER_NAME=$(echo "$FILENAME" | sed 's/.tar.gz//')

# 3. Check if we already have it
if [ -d "$STEAM_DIR/$FOLDER_NAME" ]; then
    echo "✅ GE-Proton is already up to date: $FOLDER_NAME"
    exit 0
fi

# 4. Download and Install
echo "⬇️  New version found: $FOLDER_NAME"
echo "⬇️  Downloading..."
curl -L -o "/tmp/$FILENAME" "$DOWNLOAD_URL"

echo "📦 Extracting to Steam..."
tar -xf "/tmp/$FILENAME" -C "$STEAM_DIR"

# 5. Cleanup
rm "/tmp/$FILENAME"
echo "✨ Installed $FOLDER_NAME successfully!"