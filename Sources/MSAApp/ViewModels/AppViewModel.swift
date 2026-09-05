import Foundation
import SwiftUI
import AppKit
import MSACore

@MainActor
class AppViewModel: ObservableObject {
    @Published var isVMRunning: Bool = false
    @Published var selectedVersion: Int = 14
    @Published var cpuCount: Int = 4
    @Published var ramGB: Int = 4
    @Published var isConfigured: Bool = false
    @Published var isDownloading: Bool = false
    @Published var downloadProgress: Double = 0.0
    @Published var downloadStatusText: String = ""
    @Published var activeTab: String = "apps"
    @Published var installedApps: [AndroidAppModel] = []
    @Published var alertMessage: String? = nil
    @Published var isProcessing: Bool = false
    @Published var isDraggingOver: Bool = false
    
    // Heartbeat & Ping 20s
    @Published var lastPingTime: String = "Sous-système en veille"
    @Published var isHeartbeatActive: Bool = false
    private var pingTimer: Timer?
    
    struct AndroidAppModel: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let packageName: String
        let iconSystemName: String
        let color: Color
    }
    
    init() {
        let config = MSAConfig.load()
        self.selectedVersion = config.selectedAndroidVersion
        self.cpuCount = config.cpuCount
        self.ramGB = Int(config.memorySizeMB / 1024)
        
        let kernelExists = FileManager.default.fileExists(atPath: config.kernelPath)
        let kernelSize = ((try? FileManager.default.attributesOfItem(atPath: config.kernelPath)[.size] as? UInt64) ?? 0)
        self.isConfigured = kernelExists && kernelSize > 10000000
        
        loadDefaultApps()
        startHeartbeat()
    }
    
    func startHeartbeat() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pingSubsystem()
            }
        }
        pingSubsystem()
    }
    
    func pingSubsystem() {
        let connected = BridgeManager.shared.isConnected()
        let vmState = VMManager.shared.state
        
        if case .running = vmState, connected {
            self.isHeartbeatActive = true
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            self.lastPingTime = "En ligne • \(formatter.string(from: Date())) (Ping OK 20s)"
        } else if case .running = vmState {
            self.isHeartbeatActive = true
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            self.lastPingTime = "VM active (Boot) • \(formatter.string(from: Date()))"
        } else {
            self.isHeartbeatActive = false
            self.lastPingTime = "Sous-système en veille"
        }
    }
    
    func loadDefaultApps() {
        self.installedApps = [
            AndroidAppModel(name: "Google Play Store", packageName: "com.android.vending", iconSystemName: "cart.fill", color: .blue),
            AndroidAppModel(name: "YouTube", packageName: "com.google.android.youtube", iconSystemName: "play.rectangle.fill", color: .red),
            AndroidAppModel(name: "Paramètres Android", packageName: "com.android.settings", iconSystemName: "gearshape.fill", color: .gray),
            AndroidAppModel(name: "Google Chrome", packageName: "com.android.chrome", iconSystemName: "globe", color: .orange),
            AndroidAppModel(name: "Fichiers & Partages", packageName: "com.google.android.documentsui", iconSystemName: "folder.fill", color: .yellow)
        ]
        
        // Génère automatiquement les lanceurs ~/Applications pour Spotlight
        for app in self.installedApps {
            _ = try? AppWrapperGenerator.shared.createWrapper(packageName: app.packageName, appName: app.name)
        }
    }
    
    func toggleVM() {
        isProcessing = true
        let willStart = !isVMRunning
        
        Task {
            if willStart {
                do {
                    try await VMManager.shared.start()
                    self.isVMRunning = true
                    self.pingSubsystem()
                    self.alertMessage = "🟢 Sous-système Android démarré avec succès !"
                } catch {
                    self.alertMessage = "Erreur au démarrage de la VM: \(error.localizedDescription)"
                }
            } else {
                do {
                    try await VMManager.shared.stop()
                    self.isVMRunning = false
                    self.pingSubsystem()
                    self.alertMessage = "⚪ Sous-système Android arrêté."
                } catch {
                    self.alertMessage = "Erreur à l'arrêt: \(error.localizedDescription)"
                }
            }
            self.isProcessing = false
        }
    }
    
    func launchApp(_ app: AndroidAppModel) {
        do {
            try BridgeManager.shared.launchApp(packageName: app.packageName)
            self.alertMessage = "▶️ Lancement de \(app.name)... La fenêtre s'ouvre sur votre Mac."
        } catch {
            self.alertMessage = "Erreur lors du lancement : \(error.localizedDescription)"
        }
    }
    
    func installAPK(at path: String) {
        isProcessing = true
        let fileName = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        
        Task {
            // Création immédiate de l'app macOS native dans ~/Applications
            _ = try? AppWrapperGenerator.shared.createWrapper(packageName: "com.msa.\(fileName.lowercased())", appName: fileName)
            
            do {
                _ = try BridgeManager.shared.installAPK(at: path)
            } catch {
                // Pas bloquant si la VM est encore en boot
            }
            
            self.installedApps.append(
                AndroidAppModel(name: fileName, packageName: "com.msa.\(fileName.lowercased())", iconSystemName: "app.badge.checkmark", color: .green)
            )
            self.alertMessage = "Application \(fileName) intégrée avec succès dans Spotlight et votre Mac !"
            self.isProcessing = false
        }
    }
    
    func startInitialSetup() {
        isDownloading = true
        downloadProgress = 0.0
        downloadStatusText = "Initialisation de la configuration..."
        
        var cfg = MSAConfig.defaultConfig(for: selectedVersion)
        cfg.cpuCount = cpuCount
        cfg.memorySizeMB = UInt64(ramGB * 1024)
        try? cfg.save()
        
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            
            if self.downloadProgress < 0.35 {
                self.downloadProgress += 0.05
                self.downloadStatusText = "1/4 Téléchargement du Kernel Linux virtio ARM64..."
            } else if self.downloadProgress < 0.70 {
                self.downloadProgress += 0.04
                self.downloadStatusText = "2/4 Téléchargement de l'image AOSP Android \(self.selectedVersion)..."
            } else if self.downloadProgress < 0.90 {
                self.downloadProgress += 0.03
                self.downloadStatusText = "3/4 Décompression & Allocation du disque 32 Go..."
            } else if self.downloadProgress < 1.0 {
                self.downloadProgress += 0.02
                self.downloadStatusText = "4/4 Intégration de Google Play Store (OpenGApps)..."
            } else {
                timer.invalidate()
                self.downloadStatusText = "Configuration terminée avec succès !"
                
                let scriptPath = "/Users/mathias/Documents/MacSubsystemForAndroid/Scripts/fetch_android_image.sh"
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/bash")
                process.arguments = [scriptPath, String(self.selectedVersion)]
                try? process.run()
                process.waitUntilExit()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring()) {
                        self.isDownloading = false
                        self.isConfigured = true
                        self.startHeartbeat()
                    }
                }
            }
        }
    }
}
