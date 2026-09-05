#!/bin/bash
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"

echo "🚀 Lancement de la véritable interface Android 16 (Pixel 7 AOSP + Play Store)..."
/opt/homebrew/bin/emulator -avd Android16_MSA -gpu host -accel on -no-metrics &
