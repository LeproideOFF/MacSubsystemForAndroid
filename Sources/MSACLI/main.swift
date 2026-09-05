import Foundation
import MSACore

let args = CommandLine.arguments

func printUsage() {
    print("""
    🍏 MSA - Mac Subsystem for Android (CLI)
    Compatible: Apple Silicon M1, M2, M3, M4, M5+
    
    Usage: msa <command> [options]
    
    Commands:
      setup              Interactive Android version selector (Android 6 to 17)
      download           Download & prepare AOSP images for the selected version
      start              Start the Android microVM daemon
      stop               Stop the Android microVM
      status             Show current subsystem status & selected Android version
      install <path.apk> Install an Android APK file
      launch <package>   Launch an installed Android app
      list               List installed user apps
      wrap <package> <name> Generate native macOS .app launcher
    """)
}

guard args.count > 1 else {
    printUsage()
    exit(0)
}

let command = args[1]

switch command {
case "setup":
    print("\n═════════════════════════════════════════════════════════")
    print("🤖 Mac Subsystem for Android (MSA) - Sélection de version")
    print("═════════════════════════════════════════════════════════")
    print("Choisissez la version d'Android à exécuter sur votre Mac:\n")
    
    for version in AndroidVersion.allCases {
        let numStr = String(format: "%2d", version.rawValue)
        let rec = version.isRecommended ? "  ⭐ [Recommandé]" : ""
        print("  [\(numStr)] Android \(version.rawValue) (\(version.codename))\(rec)")
    }
    
    print("\nEntrez le numéro de version souhaité (6 à 17) [Par défaut: 13] : ", terminator: "")
    fflush(stdout)
    
    let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let chosenNumber = Int(input) ?? 13
    
    guard let selectedVersion = AndroidVersion(rawValue: chosenNumber) else {
        print("❌ Version invalide. Veuillez choisir un entier entre 6 et 17.")
        exit(1)
    }
    
    print("\n⚙️ Configuration de l'environnement pour Android \(selectedVersion.rawValue) (\(selectedVersion.codename))...")
    let config = MSAConfig.defaultConfig(for: selectedVersion.rawValue)
    
    do {
        try config.save()
        print("✅ Configuration sauvegardée dans ~/.msa/config.json")
        print("📁 Dossier système : \(config.dataDirectory)")
        print("\n🎉 Android \(selectedVersion.rawValue) est désormais sélectionné comme système actif pour MSA.")
        print("👉 Tapez 'msa download' pour récupérer les images système correspondantes.")
        print("👉 Tapez 'msa start' pour démarrer le sous-système.")
    } catch {
        print("❌ Erreur lors de la sauvegarde de la configuration : \(error)")
        exit(1)
    }

case "download":
    let currentConfig = MSAConfig.load()
    let scriptPath = "/Users/mathias/Documents/MacSubsystemForAndroid/Scripts/fetch_android_image.sh"
    print("📥 Lancement du téléchargement des composants pour Android \(currentConfig.selectedAndroidVersion)...")
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.arguments = [scriptPath, String(currentConfig.selectedAndroidVersion)]
    try? process.run()
    process.waitUntilExit()

case "start":
    let currentConfig = MSAConfig.load()
    print("🚀 Initialisation du sous-système Android \(currentConfig.selectedAndroidVersion) (Virtualization.framework)...")
    
    guard FileManager.default.fileExists(atPath: currentConfig.kernelPath) else {
        print("❌ Le kernel pour Android \(currentConfig.selectedAndroidVersion) est manquant dans \(currentConfig.kernelPath).")
        print("👉 Exécutez 'msa download' pour initialiser les images de cette version.")
        exit(1)
    }
    
    Task {
        do {
            try await VMManager.shared.start()
            print("✅ Android Subsystem démarré avec succès.")
            dispatchMain()
        } catch {
            print("❌ Erreur au démarrage du sous-système: \(error.localizedDescription)")
            exit(1)
        }
    }
    dispatchMain()

case "status":
    let currentConfig = MSAConfig.load()
    print("═════════════════════════════════════════════════════════")
    print("🍏 Statut de Mac Subsystem for Android (MSA)")
    print("═════════════════════════════════════════════════════════")
    print("• Version Android active : Android \(currentConfig.selectedAndroidVersion)")
    print("• Cœurs CPU alloués      : \(currentConfig.cpuCount)")
    print("• Mémoire RAM allouée    : \(currentConfig.memorySizeMB) MB")
    print("• Dossier de données     : \(currentConfig.dataDirectory)")
    print("• Architecture hôte      : Apple Silicon (M1/M2/M3/M4/M5+)")
    
    if BridgeManager.shared.isConnected() {
        print("• Connexion ADB          : 🟢 En ligne & Connecté")
    } else {
        print("• Connexion ADB          : ⚪ VM en attente de démarrage ('msa start')")
    }

case "list":
    do {
        let apps = try BridgeManager.shared.listInstalledApps()
        print("📦 Applications Android installées (\(apps.count)):")
        for app in apps {
            print("  • \(app)")
        }
    } catch {
        print("❌ Erreur lors de la récupération des apps: \(error)")
    }

case "install":
    guard args.count > 2 else {
        print("Usage: msa install <chemin-du-fichier.apk>")
        exit(1)
    }
    let apkPath = args[2]
    print("📥 Installation de \(apkPath)...")
    do {
        let result = try BridgeManager.shared.installAPK(at: apkPath)
        print("✅ \(result)")
    } catch {
        print("❌ Échec de l'installation: \(error)")
    }

case "launch":
    guard args.count > 2 else {
        print("Usage: msa launch <package-name>")
        exit(1)
    }
    let package = args[2]
    print("▶️ Lancement de \(package)...")
    do {
        try BridgeManager.shared.launchApp(packageName: package)
        print("✅ Application lancée.")
    } catch {
        print("❌ Échec du lancement: \(error)")
    }

case "wrap":
    guard args.count > 3 else {
        print("Usage: msa wrap <nom.du.package> <Nom Application>")
        exit(1)
    }
    let package = args[2]
    let name = args[3]
    do {
        let path = try AppWrapperGenerator.shared.createWrapper(packageName: package, appName: name)
        print("✨ Application macOS générée à : \(path.path)")
    } catch {
        print("❌ Erreur lors de la création du wrapper: \(error)")
    }

default:
    printUsage()
}
