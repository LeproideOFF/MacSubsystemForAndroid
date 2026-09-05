#!/bin/bash
set -e

APPS_DIR="$HOME/Applications"

function build_icns() {
    local name="$1"
    local url="$2"
    local res="$APPS_DIR/$name.app/Contents/Resources"
    mkdir -p "$res"
    mkdir -p "/tmp/$name.iconset"
    
    echo "⬇️ Téléchargement icône $name..."
    curl -sL --fail "$url" -o "/tmp/$name.png"
    
    for s in 16 32 64 128 256 512; do
        sips -z $s $s "/tmp/$name.png" --out "/tmp/$name.iconset/icon_${s}x${s}.png" >/dev/null 2>&1
        sips -z $((s*2)) $((s*2)) "/tmp/$name.png" --out "/tmp/$name.iconset/icon_${s}x${s}@2x.png" >/dev/null 2>&1
    done
    
    iconutil -c icns "/tmp/$name.iconset" -o "$res/AppIcon.icns" >/dev/null 2>&1
    rm -rf "/tmp/$name.iconset" "/tmp/$name.png"
    
    # Register CFBundleIconFile in Info.plist
    local plist="$APPS_DIR/$name.app/Contents/Info.plist"
    if [ -f "$plist" ] && ! grep -q "CFBundleIconFile" "$plist"; then
        sed -i '' 's/<\/dict>/    <key>CFBundleIconFile<\/key><string>AppIcon<\/string>\
<\/dict>/' "$plist"
    fi
    touch "$APPS_DIR/$name.app"
    echo "✅ Icône officielle installée pour $name"
}

build_icns "YouTube" "https://upload.wikimedia.org/wikipedia/commons/thumb/0/09/YouTube_full-color_icon_%282017%29.svg/512px-YouTube_full-color_icon_%282017%29.svg.png"
build_icns "Google Play Store" "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7a/Google_Play_2022_logo.svg/512px-Google_Play_2022_logo.svg.png"
build_icns "Parametres Android" "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d7/Android_robot.svg/512px-Android_robot.svg.png"

# Force macOS to reload icon caches
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
