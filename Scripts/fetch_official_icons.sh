#!/bin/bash
set -e

APPS_DIR="$HOME/Applications"

function install_official_icon() {
    local name="$1"
    local url="$2"
    local app_path="$APPS_DIR/$name.app"
    local res_path="$app_path/Contents/Resources"
    local iconset="/tmp/${name}.iconset"
    
    echo "⬇️ Téléchargement icône officielle : $name..."
    mkdir -p "$res_path"
    mkdir -p "$iconset"
    
    curl -k -sL "$url" -o "/tmp/${name}.png"
    
    for s in 16 32 64 128 256 512; do
        sips -z $s $s "/tmp/${name}.png" --out "$iconset/icon_${s}x${s}.png" >/dev/null 2>&1
        sips -z $((s*2)) $((s*2)) "/tmp/${name}.png" --out "$iconset/icon_${s}x${s}@2x.png" >/dev/null 2>&1
    done
    
    iconutil -c icns "$iconset" -o "$res_path/AppIcon.icns" >/dev/null 2>&1
    rm -rf "$iconset" "/tmp/${name}.png"
    
    # Plist registration
    local plist="$app_path/Contents/Info.plist"
    if [ -f "$plist" ] && ! grep -q "CFBundleIconFile" "$plist"; then
        sed -i '' 's/<\/dict>/    <key>CFBundleIconFile<\/key><string>AppIcon<\/string>\
<\/dict>/' "$plist"
    fi
    
    # Force Finder refresh on this exact bundle
    touch "$app_path"
    echo "✅ $name : icône officielle installée avec succès !"
}

install_official_icon "YouTube" "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/youtube.png"
install_official_icon "Google Play Store" "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/google-play.png"
install_official_icon "Parametres Android" "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/android.png"

# Force CoreServices register
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APPS_DIR/YouTube.app"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APPS_DIR/Google Play Store.app"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APPS_DIR/Parametres Android.app"

killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
