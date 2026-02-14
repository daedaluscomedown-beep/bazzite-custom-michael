#!/usr/bin/env bash

set -e

STEAM_COMPAT="$HOME/.steam/root/compatibilitytools.d"
TMP_DIR="/tmp/ge-proton"
API_URL="https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest"

mkdir -p "$STEAM_COMPAT"
mkdir -p "$TMP_DIR"

LATEST=$(curl -s $API_URL | jq -r '.tag_name')
INSTALLED=$(ls "$STEAM_COMPAT" 2>/dev/null | grep GE-Proton | sort -V | tail -n 1 || true)

if [[ "$INSTALLED" == *"$LATEST"* ]]; then
    echo "GE-Proton already up to date."
    exit 0
fi

echo "Downloading $LATEST"

URL=$(curl -s $API_URL | jq -r '.assets[] | select(.name|test("tar.gz$")) | .browser_download_url')

cd "$TMP_DIR"
wget -q "$URL" -O ge-proton.tar.gz
tar -xzf ge-proton.tar.gz
rm ge-proton.tar.gz

mv GE-Proton* "$STEAM_COMPAT"

echo "GE-Proton updated to $LATEST"
