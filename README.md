# 🍏 Mac Subsystem for Android (MSA)

**Mac Subsystem for Android (MSA)** brings native Android apps execution to macOS (Apple Silicon ARM64) without heavy emulator interfaces, mirroring the behavior of WSA (Windows Subsystem for Android).

## ✨ Features

- **🚀 Native Apple Silicon Execution**: Built using Apple's `Virtualization.framework` (VZ) for pure ARM64 hypervisor execution with 0% CPU architecture emulation overhead.
- **🪟 Seamless Native macOS Windows**: Android apps run in standalone macOS Cocoa windows with smooth Metal rendering and ProMotion display support.
- **📦 Native `.app` Wrappers**: Double-click any installed Android app directly from macOS Spotlight, Finder, or pin it to your Dock.
- **✨ Google Services & OpenGApps Support**: Integrated support for Google Play Services via MindTheGapps / MicroG.
- **📋 Unified Clipboard & Shared Folders**: Copy and paste text or files seamlessly between macOS and Android.

---

## 🏗️ Architecture

```
┌────────────────────────────────────────────────────────┐
│               macOS (Host Apple Silicon ARM64)          │
│                                                        │
│  ┌────────────────┐  ┌────────────────┐  ┌───────────┐ │
│  │ TikTok.app     │  │ WhatsApp.app   │  │ MSA Hub   │ │
│  │ (Window Cocoa) │  │ (Window Cocoa) │  │ (MenuBar) │ │
│  └───────▲────────┘  └───────▲────────┘  └─────▲─────┘ │
│          │                   │                 │       │
│          └───────────┬───────┴─────────────────┘       │
│                      │ MSA Client Bridge (Swift/IPC)   │
└──────────────────────┼─────────────────────────────────┘
                       │ vsock / Virtio / Shared Memory
┌──────────────────────▼─────────────────────────────────┐
│       MicroVM Android (Virtualization.framework)       │
│                                                        │
│  - Linux Kernel 5.x/6.x ARM64 avec drivers virtio      │
│  - Android Open Source Project (AOSP ARM64)            │
│  - Multi-Display / Freeform Window Manager             │
│  - OpenGApps / MicroG (Google Play Store & Services)  │
│  - Bridge Daemon (MSA Agent / Headless Streamer)       │
└────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### 1. Requirements
- macOS Ventura (13.0) or newer
- Apple Silicon Mac (M1, M2, M3, M4)
- Xcode Command Line Tools (`xcode-select --install`)
- ADB (`brew install android-platform-tools`)

### 2. Setup & Build

```bash
# Setup directories (~/.msa)
./Scripts/setup_environment.sh

# Build the Swift binaries
swift build -c release
```

### 3. CLI Commands

```bash
# Check subsystem status
.build/release/msa-cli status

# Install an APK
.build/release/msa-cli install /path/to/app.apk

# Launch an app
.build/release/msa-cli launch com.instagram.android

# Generate native macOS .app launcher (Spotlight & Dock ready)
.build/release/msa-cli wrap com.instagram.android "Instagram"
```

---

## 📂 Project Structure

```
MacSubsystemForAndroid/
├── Package.swift
├── README.md
├── Sources/
│   ├── MSACore/
│   │   ├── VMManager.swift            # Apple Virtualization.framework engine
│   │   ├── Config.swift               # Subsystem CPU, RAM & disk config
│   │   ├── BridgeManager.swift        # ADB & IPC bridge
│   │   └── AppWrapperGenerator.swift  # macOS .app bundle generator
│   ├── MSADaemon/
│   │   └── main.swift                 # Background headless service
│   └── MSACLI/
│       └── main.swift                 # CLI management tool
└── Scripts/
    └── setup_environment.sh           # Environment bootstrapper
```

---

## 📜 License
MIT License.
