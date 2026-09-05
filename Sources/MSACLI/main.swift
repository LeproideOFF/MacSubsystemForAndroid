import Foundation
import MSACore

let args = CommandLine.arguments

func printUsage() {
    print("""
    🤖 MSA - Mac Subsystem for Android (CLI)
    Usage: msa <command> [options]
    
    Commands:
      start              Start the Android microVM daemon
      stop               Stop the Android microVM
      status             Show current subsystem status
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
case "start":
    print("🚀 Initializing Android Subsystem (Virtualization.framework)...")
    Task {
        do {
            try await VMManager.shared.start()
            print("✅ Android Subsystem started successfully.")
            // Keep running
            RunLoop.main.run()
        } catch {
            print("❌ Failed to start Android Subsystem: \(error.localizedDescription)")
            exit(1)
        }
    }
    RunLoop.main.run()

case "status":
    print("Checking Subsystem status...")
    if BridgeManager.shared.isConnected() {
        print("🟢 Subsystem Online & Connected via ADB")
    } else {
        print("⚪ Subsystem Offline or Connecting...")
    }

case "list":
    do {
        let apps = try BridgeManager.shared.listInstalledApps()
        print("📦 Installed Android Applications (\(apps.count)):")
        for app in apps {
            print("  • \(app)")
        }
    } catch {
        print("❌ Error listing apps: \(error)")
    }

case "install":
    guard args.count > 2 else {
        print("Usage: msa install <path-to-apk>")
        exit(1)
    }
    let apkPath = args[2]
    print("📥 Installing \(apkPath)...")
    do {
        let result = try BridgeManager.shared.installAPK(at: apkPath)
        print("✅ \(result)")
    } catch {
        print("❌ Installation failed: \(error)")
    }

case "launch":
    guard args.count > 2 else {
        print("Usage: msa launch <package-name>")
        exit(1)
    }
    let package = args[2]
    print("▶️ Launching \(package)...")
    do {
        try BridgeManager.shared.launchApp(packageName: package)
        print("✅ App launch triggered.")
    } catch {
        print("❌ Launch failed: \(error)")
    }

case "wrap":
    guard args.count > 3 else {
        print("Usage: msa wrap <package-name> <App Name>")
        exit(1)
    }
    let package = args[2]
    let name = args[3]
    do {
        let path = try AppWrapperGenerator.shared.createWrapper(packageName: package, appName: name)
        print("✨ Native macOS app generated at: \(path.path)")
    } catch {
        print("❌ Failed to generate wrapper: \(error)")
    }

default:
    printUsage()
}
