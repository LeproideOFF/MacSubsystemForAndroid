#!/bin/bash
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:/opt/homebrew/bin:$PATH"

# Vérifier si l'émulateur tourne déjà
if pgrep -f "qemu-system-aarch64" > /dev/null; then
    echo "✅ Le sous-système Android 16 est déjà actif."
    # Amener le bureau ou la fenêtre au premier plan
    adb -s emulator-5554 shell "am start -a android.intent.action.MAIN -c android.intent.category.HOME" 2>/dev/null || true
    exit 0
fi

echo "🚀 Lancement d'Android 16 ARM64 en arrière-plan avec accélération Metal..."
nohup /opt/homebrew/bin/emulator -avd Android16_Pixel -gpu host -accel on -no-metrics -no-snapshot-load > /tmp/msa_emulator.log 2>&1 &

# Attendre que le sous-système soit prêt
for i in {1..30}; do
    if adb -s emulator-5554 get-state 2>/dev/null | grep -q "device"; then
        echo "✅ Sous-système Android 16 connecté !"
        # Configurer l'orientation et résolution tablette moderne adaptée au Mac
        adb -s emulator-5554 shell "wm size 1920x1200" 2>/dev/null || true
        adb -s emulator-5554 shell "wm density 280" 2>/dev/null || true
        # Appliquer les optimisations d'économie d'énergie
        adb -s emulator-5554 shell "settings put global window_animation_scale 0.0" 2>/dev/null || true
        adb -s emulator-5554 shell "settings put global transition_animation_scale 0.0" 2>/dev/null || true
        adb -s emulator-5554 shell "settings put global animator_duration_scale 0.0" 2>/dev/null || true
        break
    fi
    sleep 1
done
