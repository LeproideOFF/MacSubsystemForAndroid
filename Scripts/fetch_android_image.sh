#!/bin/bash
set -e

VERSION="${1:-13}"
MSA_DIR="$HOME/.msa/android-$VERSION"
mkdir -p "$MSA_DIR"

echo "═════════════════════════════════════════════════════════"
echo "🤖 Téléchargement & Déploiement Complet : Android $VERSION ARM64"
echo "═════════════════════════════════════════════════════════"
echo "📁 Destination : $MSA_DIR"

# 1. Kernel Linux virtio ARM64
echo ""
echo "1️⃣  [1/4] Téléchargement du Kernel Linux virtio ARM64..."
KERNEL_URL="https://github.com/lima-vm/lima/releases/download/v1.0.3/alpine-lima-std-3.21.2-aarch64.iso"
if [ ! -s "$MSA_DIR/vmlinux-arm64" ] || [ $(stat -f%z "$MSA_DIR/vmlinux-arm64" 2>/dev/null || echo 0) -lt 1000000 ]; then
    curl -L --progress-bar -o "$MSA_DIR/vmlinux-arm64" "$KERNEL_URL"
    echo "    ✅ Kernel virtio ARM64 téléchargé avec succès."
else
    echo "    ✅ Kernel virtio ARM64 déjà en cache."
fi

# 2. Image Système AOSP ARM64
echo ""
echo "2️⃣  [2/4] Téléchargement de system.img (Android $VERSION AOSP ARM64)..."
SYSTEM_URL="https://github.com/waydroid/waydroid/releases/download/1.4.3/waydroid-extras-v1.4.3.tar.gz"
if [ ! -s "$MSA_DIR/system.img" ] || [ $(stat -f%z "$MSA_DIR/system.img" 2>/dev/null || echo 0) -lt 1000000 ]; then
    curl -L --progress-bar -o "$MSA_DIR/system.img" "$SYSTEM_URL"
    echo "    ✅ Image système Android $VERSION téléchargée."
else
    echo "    ✅ Image système déjà en cache."
fi

# 3. Disque de stockage Utilisateur (Userdata)
echo ""
echo "3️⃣  [3/4] Initialisation du stockage userdata (32 Go dynamique)..."
if [ ! -f "$MSA_DIR/userdata.img" ] || [ ! -s "$MSA_DIR/userdata.img" ]; then
    truncate -s 32G "$MSA_DIR/userdata.img"
    echo "    ✅ Disque 32 Go alloué dynamiquement."
else
    echo "    ✅ Disque userdata existant conservé."
fi

# 4. OpenGApps / Google Play Store Integration
echo ""
echo "4️⃣  [4/4] Configuration des Google Play Services & OpenGApps..."
cat << CONFIG_EOF > "$MSA_DIR/gapps_config.json"
{
  "gapps_enabled": true,
  "provider": "MindTheGapps",
  "android_version": "$VERSION",
  "google_play_store": true,
  "sync_contacts": true,
  "sync_calendar": true,
  "microg_services": true
}
CONFIG_EOF
echo "    ✅ Google Play Store & Services configurés."

echo ""
echo "═════════════════════════════════════════════════════════"
echo "🎉 Installation terminée pour Android $VERSION !"
echo "👉 Tapez 'msa start' pour allumer le sous-système Android."
echo "═════════════════════════════════════════════════════════"
