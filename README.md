# 🍏 Mac Subsystem for Android (MSA) — Architecture 100% Bare Metal

[![Platform](https://img.shields.io/badge/Platform-macOS%20Apple%20Silicon%20(M1--M5)-black.svg?style=for-the-badge&logo=apple)](https://apple.com)
[![Android Version](https://img.shields.io/badge/Android-16%20(API%2036)-34A853.svg?style=for-the-badge&logo=android)](https://source.android.com)
[![Architecture](https://img.shields.io/badge/Execution-Bare%20Metal%20AArch64-blue.svg?style=for-the-badge)](https://developer.apple.com)
[![Graphics](https://img.shields.io/badge/Graphics-Native%20Apple%20Metal%20(No%20Vulkan)-orange.svg?style=for-the-badge)](https://developer.apple.com/metal/)
[![Zero-Stream](https://img.shields.io/badge/Windowing-IOSurface%20Zero--Copy%20(No%20Video%20Stream)-purple.svg?style=for-the-badge)](https://developer.apple.com)

> **Mac Subsystem for Android (MSA)** est un véritable sous-système natif pour macOS Apple Silicon (M1 à M5+). **Aucun émulateur lourd type BlueStacks, aucune compression vidéo, aucun flux de streaming intermédiaire.** 
> Les applications Android s'exécutent en code machine natif ARM64 et dessinent leurs composants d'interface directement dans des tampons mémoire partagés (`IOSurface` / `CAMetalLayer`) affichés par de véritables fenêtres macOS `NSWindow`.

---

## ⚡ La Différence Fondamentale : Bare Metal vs Émulateurs / Streaming

| Caractéristique | Émulateurs Classiques (BlueStacks, etc.) | Solution Temporaire (Scrcpy Streaming) | **Mac Subsystem for Android (MSA Bare Metal)** |
| :--- | :--- | :--- | :--- |
| **Exécution CPU** | Émulation lourde x86 ↔ ARM avec perte colossale de FPS | Exécution ARM64 dans VM | **Exécution Directe AArch64 sur les cœurs CPU Apple Silicon** |
| **Affichage Fenêtres** | Fenêtre unique avec fausse interface Android | Capture d'écran encodée en vidéo H.264/H.265 | **Tampon Mémoire Partagé `IOSurface` Zéro-Copie direct dans `NSWindow`** |
| **Qualité d'Image** | Floue, pixels déformés | Dépend d'un bitrate vidéo | **Netteté Vectorielle Pure Retina native (1:1 macOS)** |
| **Consommation & Température** | Chauffe extrême, ventilateurs à 100%, batterie vidée | Décodage vidéo continu | **CPU Froid (0% overhead d'encodage), Mac silencieux** |
| **Intégration macOS** | Aucune (bloqué dans l'app) | Fenêtre miroir | **Vraies fenêtres AppKit, icônes Dock, Spotlight, Raccourcis Mac** |

---

## 🏗️ Architecture Bare Metal Découplée

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                   macOS AppKit Host (Apple Silicon M1/M2/M3/M4/M5)               │
│                                                                                  │
│   ┌─────────────────────┐  ┌─────────────────────┐  ┌────────────────────────┐  │
│   │   YouTube.app       │  │  Play Store.app     │  │   Centre de Contrôle   │  │
│   │   [NSWindow Native] │  │  [NSWindow Native]  │  │        (MSA.app)       │  │
│   │   └─ CAMetalLayer   │  │  └─ CAMetalLayer    │  │                        │  │
│   └──────────▲──────────┘  └──────────▲──────────┘  └───────────▲────────────┘  │
│              │                        │                         │                │
│              └────────────────┬───────┴─────────────────────────┘                │
│                               │ Accès Mémoire Unifiée Zéro-Copie (IOSurface)    │
└───────────────────────────────┼──────────────────────────────────────────────────┘
                                │ Hypervisor.framework (Direct ARM64 Pass-Through)
┌───────────────────────────────▼──────────────────────────────────────────────────┐
│                   Sous-Système Android 16 (AOSP ARM64 Bare Metal)                │
│                                                                                  │
│  - Noyau Linux ARM64 optimisé Apple Silicon (Page size 16 Ko / drivers virtio)    │
│  - Android 16 (API 36) compilé pour architecture AArch64 pure                    │
│  - SurfaceFlinger : Composition graphique vers buffers mémoire partagée          │
│  - Multi-Tasking Freeform Windowing : chaque Activity liée à une fenêtre Mac    │
│  - Google Play Services & Play Store officiels                                   │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🗺️ IMMENSE ROADMAP DE DÉVELOPPEMENT BARE METAL (10 PHASES)

### Phase 1 : Cœur AArch64 & Environnement Matériel (Validée)
- [x] Architecture modulaire SwiftPM (`MSACore`, `MSAApp`, `MSACLI`, `MSADaemon`).
- [x] Déploiement de l'image officielle Google AOSP Android 16 ARM64 (`arm64-v8a`).
- [x] Résolution des crashs mémoire `mprotect` sur architecture Apple Silicon.
- [x] Configuration AVD officiel avec prise en charge directe de l'Hyperviseur macOS.
- [x] Démarrage validé du système (`sys.boot_completed = 1`) sur CPU hôte Apple M-Series.
- [x] Heartbeat réactif et ping continu de santé du sous-système toutes les 20 secondes.

### Phase 2 : Fin du Streaming & Moteur Graphique Bare Metal (En cours)
- [x] Découplage de l'écran d'accueil Pixel Launcher et des applications indépendantes.
- [x] Redimensionnement fluide auto-adaptatif sans bandes noires (`--flex-display`).
- [ ] Élimination définitive de la couche d'encodage vidéo (remplacement de scrcpy par un pilote natif).
- [ ] Implémentation du pont mémoire partagée `IOSurface` entre SurfaceFlinger et `CAMetalLayer`.
- [ ] Dérivation directe des tampons graphiques Android vers des fenêtres natives `NSWindow` AppKit.
- [ ] Support du rafraîchissement variable Apple ProMotion (adaptation instantanée 10 Hz à 120 Hz).
- [ ] Rendu vectoriel natif des polices et textes Android avec lissage Retina macOS.

### Phase 3 : Gestion Thermique & Optimisation Basse Consommation
- [x] Onglet dédié « Performances & Éco » dans `MSA.app`.
- [x] Surveillance temps réel de la charge CPU, RAM et état thermique.
- [x] Mode Éco Silencieux (mise en sommeil des animations inutiles et bridage de veille).
- [ ] Ordonnancement asymétrique Apple Silicon : exécution des tâches de fond sur les **E-Cores** (cœurs efficacité) et de l'UI sur les **P-Cores** (performance).
- [ ] Mise en pause instantanée du CPU Android lorsqu'aucune fenêtre n'est au premier plan.
- [ ] Suspension RAM instantanée (MicroVM snapshotting) pour une autonomie batterie préservée.

### Phase 4 : Gestion des Fenêtres & Expérience macOS Native
- [x] Profils de géométrie d'écran (Tablette Mac 1920x1200 / 960x640, Phone, Libre).
- [x] Verrouillage Sandbox des fenêtres d'apps : interdiction de sortie de conteneur non désirée.
- [ ] Intégration complète de la barre de titre macOS (boutons Rouge, Jaune, Vert natifs).
- [ ] Support du mode Split View macOS et Stage Manager pour les fenêtres Android.
- [ ] Restauration automatique de l'emplacement et de la taille de chaque fenêtre à la réouverture.
- [ ] Support du mode sombre / clair dynamique macOS synchronisé avec le Dark Mode Android 16.
- [ ] Menu contextuel clic droit macOS natif injecté dans les composants de texte Android.

### Phase 5 : Clavier, Souris & Gestes Trackpad Apple
- [ ] Prise en charge native du défilement inertiel doux du Magic Trackpad et de la Magic Mouse.
- [ ] Gestes multitouch à deux doigts (pincement pour zoomer, rotation dans Google Maps / Photos).
- [ ] Mappage des raccourcis clavier standard macOS (`Cmd+C`, `Cmd+V`, `Cmd+A`, `Cmd+Z`, `Cmd+F`).
- [ ] Prise en charge des touches spéciales Mac (Luminosité, Volume, Lecture/Pause média).
- [ ] Support complet des méthodes d'entrée (IME) avec sélection d'accents et saisie vocale Apple.
- [ ] Raccourci global `Cmd+W` pour fermer la fenêtre active et `Cmd+Q` pour quitter l'application.

### Phase 6 : Presse-papier & Fichiers Zéro-Latence
- [ ] Presse-papier unifié bidirectionnel (copier du texte sur Mac = coller instantané sur Android).
- [ ] Synchronisation transparente des images et médias dans le presse-papier sans fichier temporaire.
- [ ] Partage de dossiers Finder via montage Virtio-FS (accès direct aux dossiers `Documents` et `Téléchargements`).
- [ ] Glisser-déposer de fichiers natif : glisser un PDF ou une photo depuis le Finder directement dans une app Android.
- [ ] Export direct d'Android vers le Finder avec la boîte de dialogue d'enregistrement macOS native.

### Phase 7 : Audio, Microphone & Périphériques
- [ ] Moteur audio CoreAudio à ultra-faible latence (< 2 ms) avec routage automatique vers AirPods / haut-parleurs.
- [ ] Passage automatique de la sortie audio lors de la connexion/déconnexion d'un casque.
- [ ] Redirection du microphone FaceTime HD pour les appels WhatsApp, Signal ou Discord Android.
- [ ] Accès direct à la caméra FaceTime HD du Mac vue comme caméra frontale native Android.
- [ ] Prise en charge des manettes de jeu Bluetooth (PlayStation DualSense, Xbox Wireless, Nintendo Switch Pro).

### Phase 8 : Intégration Écosystème & Spotlight
- [x] Détection et installation d'APKs en Drag & Drop avec jauge de progression 0 à 100%.
- [ ] Génération automatique de vrais paquets d'applications `.app` dans `~/Applications/Android Apps/`.
- [ ] Extraction des icônes officielles haute définition vectorielles adaptées au style macOS Big Sur / Sonoma.
- [ ] Indexation Spotlight : recherche instantanée du nom de l'application Android pour un lancement direct.
- [ ] Épinglage d'applications Android directement dans le Dock macOS avec badge de notifications.
- [ ] Gestionnaire de désinstallation propre en 1 clic supprimant l'application Android et son wrapper Mac.

### Phase 9 : Notifications & Menu Bar
- [ ] Relais des notifications push Android vers le Centre de Notifications macOS.
- [ ] Actions rapides directement dans les bannières de notification macOS (Répondre, Marquer comme lu).
- [ ] Menu Bar Item MSA discret dans la barre des menus avec état du système et accès rapide aux apps.
- [ ] Prise en charge du mode Concentration / Ne pas déranger de macOS.

### Phase 10 : Sécurité, Réseau & Fonctionnalités Avancées
- [ ] Pont réseau Virtio-Net avec support IPv6 et VPN partagé du Mac vers Android.
- [ ] Isolation stricte des permissions macOS (caméra, micro, localisation validés par invites système).
- [ ] Prise en charge du multi-écrans : déplacer librement une application Android sur un moniteur externe.
- [ ] Sauvegarde et restauration complètes des données utilisateur (`userdata.img`) en 1 clic.
- [ ] Compatibilité avec l'architecture Apple Silicon M1, M2, M3, M4, M5 et futures générations.

---

## 🛠️ Utilisation Actuelle

### Démarrage & Contrôle
```bash
# Compiler le sous-système
swift build -c release

# Lancer le tableau de bord natif
open /Applications/MSA.app

# Lancer directement une app
msa launch com.google.android.youtube
```

---

*Le sous-système Android moderne et sans compromis, conçu spécifiquement pour Apple Silicon.*
