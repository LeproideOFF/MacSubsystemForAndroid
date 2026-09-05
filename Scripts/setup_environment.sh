#!/bin/bash
set -e

MSA_DIR="$HOME/.msa"
IMAGES_DIR="$MSA_DIR/images"
APPS_DIR="$HOME/Applications/Android Apps"

echo "🤖 Initializing MSA directories..."
mkdir -p "$IMAGES_DIR"
mkdir -p "$APPS_DIR"

echo "✅ Created $MSA_DIR"
echo "✅ Created $APPS_DIR"

echo "🔍 Checking dependencies..."
if ! command -v adb &> /dev/null; then
    echo "⚠️ ADB is not installed. Installing via brew..."
    brew install android-platform-tools
fi

if ! command -v scrcpy &> /dev/null; then
    echo "💡 Installing scrcpy for seamless low-latency window forwarding..."
    brew install scrcpy
fi

echo "🎉 Environment setup complete."
