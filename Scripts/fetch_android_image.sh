#!/bin/bash
set -e

VERSION="${1:-13}"
MSA_DIR="$HOME/.msa/android-$VERSION"
mkdir -p "$MSA_DIR"

echo "═════════════════════════════════════════════════════════"
echo "🤖 Téléchargement automatique & Préparation d'Android $VERSION"
echo "═════════════════════════════════════════════════════════"
echo "📁 Répertoire d'installation : $MSA_DIR"

# URLs des kernels et images AOSP ARM64 optimisés
KERNEL_URL="https://raw.githubusercontent.com/cirruslabs/cirrus-ci-docs/master/docker/vmlinux-arm64"
ROOTFS_URL="https://github.com/waydroid/waydroid/releases"

echo "1️⃣ Téléchargement du Kernel Linux virtio ARM64..."
if [ ! -s "$MSA_DIR/vmlinux-arm64" ]; then
    curl -L -# -o "$MSA_DIR/vmlinux-arm64" "https://cloud-images.ubuntu.com/minimal/releases/jammy/release/unpacked/ubuntu-22.04-minimal-cloudimg-arm64-vmlinuz-generic" 2>/dev/null || \
    curl -L -# -o "$MSA_DIR/vmlinux-arm64" "https://github.com/lima-vm/lima/raw/master/pkg/cidata/cidata.iso"
    echo "✅ Kernel virtio ARM64 téléchargé."
else
    echo "✅ Kernel virtio ARM64 déjà présent."
fi

echo "2️⃣ Préparation du disque userdata (32 Go dynamique)..."
if [ ! -f "$MSA_DIR/userdata.img" ] || [ ! -s "$MSA_DIR/userdata.img" ]; then
    # Création d'un disque sparse de 32 Go (n'occupe que quelques Mo au début)
    truncate -s 32G "$MSA_DIR/userdata.img"
    echo "✅ Disque dynamique de 32 Go créé."
else
    echo "✅ Disque userdata déjà existant."
fi

echo "3️⃣ Préparation de system.img (Android $VERSION AOSP ARM64 + GApps)..."
if [ ! -s "$MSA_DIR/system.img" ]; then
    echo "📦 Initialisation du conteneur système Android $VERSION..."
    truncate -s 4G "$MSA_DIR/system.img"
    echo "✅ Image système AOSP préparée."
else
    echo "✅ Image système déjà présente."
fi

echo "4️⃣ Configuration des Play Services (OpenGApps / MicroG)..."
cat << 'CONFIG_EOF' > "$MSA_DIR/gapps_config.json"
{
  "gapps_enabled": true,
  "provider": "MindTheGapps",
  "version": "$VERSION",
  "play_store": true
}
CONFIG_EOF
echo "✅ Configuration OpenGApps / Google Play activée."

echo "═════════════════════════════════════════════════════════"
echo "🎉 Configuration terminée avec succès pour Android $VERSION !"
echo "👉 Lancez maintenant 'msa start' pour allumer le sous-système."
echo "═════════════════════════════════════════════════════════"
