# 🍏 Mac Subsystem for Android (MSA)

[![Platform](https://img.shields.io/badge/Platform-macOS%20Apple%20Silicon%20(M1--M5)-black.svg?style=for-the-badge&logo=apple)](https://apple.com)
[![Android Version](https://img.shields.io/badge/Android-16%20(Vanilla%20Ice%20Cream%20/%20Baklava)-34A853.svg?style=for-the-badge&logo=android)](https://source.android.com)
[![Architecture](https://img.shields.io/badge/Architecture-ARM64%20%2F%20AArch64%20Direct%20Execution-blue.svg?style=for-the-badge)](https://developer.apple.com)
[![Graphics](https://img.shields.io/badge/GPU-Metal%20Accelerated%20Vulkan-orange.svg?style=for-the-badge)](https://developer.apple.com/metal/)
[![License](https://img.shields.io/badge/License-Apache%202.0-red.svg?style=for-the-badge)](LICENSE)

> **Mac Subsystem for Android (MSA)** brings native Android apps execution to macOS Apple Silicon without typical heavy emulator clutter, mirroring and exceeding the seamless experience of WSA (Windows Subsystem for Android). Built from the ground up for Apple Silicon (M1, M2, M3, M4, M5+), with official Google AOSP ARM64 system images, Google Play Store integration, multi-windowing, and zero-heating thermal management.

---

## 🌟 Points Clés & Fonctionnalités Réelles

- **⚡ Exécution Directe AArch64 (0% Émulation CPU)** : Les applications Android tournent en code machine ARM64 direct sur les cœurs de votre puce Apple Silicon via l'accélération matérielle `Hypervisor.framework`.
- **🪟 Fenêtres Natives Découplées & Auto-Adaptatives** : Vos applications (YouTube, Play Store, etc.) s'ouvrent dans des fenêtres macOS natives indépendantes (`--flex-display`), qui adaptent automatiquement leur résolution et DPI sans étirement ni flou.
- **📱 Format Tablette & Personnalisation Complète** : Interface par défaut optimisée au ratio tablette Mac (1920x1200 / 960x640), avec sélection de profils en 1 clic (*Pixel Phone*, *Tablette Grand Écran*, *Compact*) et sliders DPI sur-mesure.
- **🏠 Bureau Pixel Launcher Intégré** : L'écran d'accueil est une application dédiée permettant d'accéder au véritable bureau Android 16 (widgets, tiroir d'applications, réglages).
- **🛍️ Google Play Store Officiel & Play Services** : Image système officielle Google APIs avec Play Store préconfiguré et opérationnel.
- **📦 Installation d'APK en Drag & Drop** : Déposez n'importe quel fichier `.apk` dans l'application avec affichage de la progression détaillée en temps réel (0 à 100%).
- **❄️ Gestion Thermique Silencieuse (Mode Éco)** : Optimisation adaptative des échelles d'animation et de la charge d'arrière-plan pour maintenir le Mac parfaitement froid et silencieux.
- **💓 Heartbeat Automatique (Ping 20s)** : Contrôle continu de l'état du sous-système avec réveil réactif sans polling agressif.

---

## 🏗️ Architecture Technique

```
┌────────────────────────────────────────────────────────────────────────────┐
│                    macOS Host (Apple Silicon ARM64 / M1-M5)                 │
│                                                                            │
│  ┌───────────────────┐  ┌───────────────────┐  ┌─────────────────────────┐ │
│  │   YouTube.app     │  │  Play Store.app   │  │        MSA.app          │ │
│  │  (Fenêtre Native) │  │  (Fenêtre Native) │  │  (Tableau de bord Swift)│ │
│  └─────────▲─────────┘  └─────────▲─────────┘  └────────────▲────────────┘ │
│            │                      │                         │              │
│            └──────────────┬───────┴─────────────────────────┘              │
│                           │ Scrcpy Streamer & ADB Unix Bridge              │
└───────────────────────────┼────────────────────────────────────────────────┘
                            │ Virtio-GPU Metal / Ranchu IPC / adb server
┌───────────────────────────▼────────────────────────────────────────────────┐
│               Sous-Système Android 16 (AOSP ARM64 Google Play)             │
│                                                                            │
│  - Noyau Linux 6.x ARM64 avec ranchu / virtio hypervisor drivers           │
│  - Android 16 (API 36 - aarch64 direct instruction pass-through)           │
│  - Rendu Graphique Metal Host via MoltenVK / Gfxstream (Apple M-Series)    │
│  - Google Play Services & Nexus Launcher                                   │
│  - Multi-windowing et gestion dynamique de la géométrie de surface         │
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 🗺️ IMMENSE ROADMAP DE DÉVELOPPEMENT (Suivi & Jalons)

Cette feuille de route détaille l'évolution complète du projet MSA, de sa genèse jusqu'à l'intégration système profonde dans macOS Sequoia et versions ultérieures.

### Phase 1 : Fondations & Image Système ARM64
- [x] Déploiement de l'environnement de build Swift (SwiftPM, modularisation `MSACore`, `MSAApp`, `MSACLI`, `MSADaemon`).
- [x] Extraction et installation de l'image officielle Google AOSP Android 16 ARM64 (`arm64-v8a`).
- [x] Résolution des crashs mémoire `mprotect` sur Apple Silicon et paramétrage de l'accélération Metal (`-gpu host -accel on`).
- [x] Initialisation de l'AVD officiel `Android16_Pixel` relié aux Google Play Services.
- [x] Validation du démarrage complet (`sys.boot_completed = 1`) sur processeur hôte AArch64.
- [x] Heartbeat réactif et ping du sous-système toutes les 20 secondes.

### Phase 2 : Isolation des Fenêtres & Expérience Utilisateur
- [x] Découplage de l'accueil et des applications : l'Accueil est une application dédiée (Pixel Launcher).
- [x] Lancement des applications dans des fenêtres macOS natives indépendantes via pipeline accéléré.
- [x] Prise en charge du redimensionnement automatique dynamique (`--flex-display`) sans déformation.
- [x] Profils d'appareils intégrés (Format Tablette Mac 1920x1200 / 960x640, Phone, Mini).
- [x] Barre de progression en temps réel pour l'installation d'APKs en Drag & Drop (avec pourcentages).
- [x] Installation et exécution validées de l'application YouTube officielle ARM64.

### Phase 3 : Gestion Thermique & Optimisations Matérielles
- [x] Onglet dédié « Performances & Éco » dans `MSA.app`.
- [x] Surveillance en direct de la charge CPU, de la mémoire partagée et de la température sous-système.
- [x] Mode Éco Silencieux / Anti-chauffe (désactivation des animations superflues, régulation adaptative).
- [ ] Profilage automatique de la fréquence de rafraîchissement ProMotion (adaptatif 30/60/120 Hz selon l'app active).
- [ ] Suspension ultra-basse consommation (Snapshots RAM instantanés à la fermeture des fenêtres).
- [ ] Gestion fine des cœurs Efficiency (E-Cores) vs Performance (P-Cores) sur Apple Silicon.

### Phase 4 : Intégration Native macOS (Deep System Integration)
- [ ] Support du glisser-déposer bidirectionnel de fichiers entre le Finder macOS et les applications Android.
- [ ] Presse-papier unifié (Clipboard universel macOS ↔ Android 16 avec synchronisation instantanée du texte et images).
- [ ] Audio bidirectionnel faible latence avec CoreAudio (micro et sortie casque/haut-parleurs).
- [ ] Transmission de la caméra FaceTime HD vers la caméra Android via virtual device.
- [ ] Support complet des raccourcis clavier macOS standard (Cmd+C, Cmd+V, Cmd+Q, Cmd+W, Cmd+Z).
- [ ] Intégration dans le Menu Bar macOS (status icon et menu déroulant rapide).

### Phase 5 : Spotlight & Lanceurs d'Applications Dédiés
- [ ] Génération automatique de paquets `.app` signés dans `~/Applications/Android Apps/` pour chaque APK installé.
- [ ] Extraction haute résolution des icônes vectorielles officielles pour affichage dans le Dock et le Launchpad.
- [ ] Indexation Spotlight : taper le nom de l'application Android dans Spotlight la lance directement.
- [ ] Gestionnaire de désinstallation propre en 1 clic supprimant l'application Android et son wrapper macOS.

### Phase 6 : Fonctionnalités Avancées & Développeurs
- [ ] Mode multi-comptes Google et profils de travail Android isolés.
- [ ] Redirection USB pour le débogage matériel et périphériques externes (manettes DualSense / Xbox, claviers MIDI).
- [ ] Mode bureau étendu (support du multi-écran macOS avec placement d'apps Android sur différents moniteurs).
- [ ] Gestionnaire de sauvegardes et snapshots de données utilisateur (`userdata.img`).
- [ ] Support d'OpenXR pour les futures applications spatiales sous visionOS / macOS.

---

## 🚀 Installation & Démarrage

### Prérequis
- Un Mac avec puce **Apple Silicon (M1, M2, M3, M4, M5 ou supérieur)**.
- **macOS Ventura (13.0)** ou plus récent (recommandé : macOS Sonoma / Sequoia).
- **Homebrew** installé sur votre machine.
- Outils en ligne de commande : `brew install android-platform-tools scrcpy`.

### Compilation et Lancement
```bash
# Cloner le dépôt
git clone https://github.com/LeproideOFF/MacSubsystemForAndroid.git
cd MacSubsystemForAndroid

# Compiler l'application et la CLI
swift build -c release

# Installer l'application native dans vos Applications
cp .build/release/msa-app /Applications/MSA.app/Contents/MacOS/MSA
codesign --force --sign - --entitlements Resources/msa.entitlements /Applications/MSA.app

# Lancer le centre de contrôle MSA
open /Applications/MSA.app
```

---

## 💻 Utilisation de la Ligne de Commande (CLI `msa`)

Le binaire `msa` permet d'automatiser toutes les tâches directement dans votre terminal :

```bash
# Vérifier l'état et la connectivité
msa status

# Démarrer le sous-système Android 16
msa start

# Installer un fichier APK avec suivi
msa install ~/Downloads/application.apk

# Lancer une application dans sa fenêtre native
msa launch com.google.android.youtube

# Arrêter proprement le sous-système
msa stop
```

---

## 🛡️ Sécurité & Entitlements

L'application MSA respecte les standards stricts de sécurité d'Apple :
- Signature avec `com.apple.security.hypervisor` et `com.apple.security.virtualization`.
- Exécution isolée des applications invitées.
- Isolation réseau et gestion sécurisée des clés ADB locales (`adb_keys`).

---

## 🤝 Contribution & Support

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une Issue pour suggérer une nouvelle fonctionnalité ou proposer une Pull Request pour cocher un jalon de la Roadmap.

---

*Développé avec passion pour l'écosystème Mac Apple Silicon.*
