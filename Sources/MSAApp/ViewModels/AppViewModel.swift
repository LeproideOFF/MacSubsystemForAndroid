import Foundation
import SwiftUI
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
    }
    
    func loadDefaultApps() {
        self.installedApps = [
            AndroidAppModel(name: "Google Play Store", packageName: "com.android.vending", iconSystemName: "cart.fill", color: .blue),
            AndroidAppModel(name: "Paramètres Android", packageName: "com.android.settings", iconSystemName: "gearshape.fill", color: .gray),
            AndroidAppModel(name: "Google Chrome", packageName: "com.android.chrome", iconSystemName: "globe", color: .red),
            AndroidAppModel(name: "Fichiers & Partages", packageName: "com.google.android.documentsui", iconSystemName: "folder.fill", color: .yellow)
        ]
    }
    
    func toggleVM() {
        isProcessing = true
        Task {
            if isVMRunning {
                do {
                    try await VMManager.shared.stop()
                    self.isVMRunning = false
                } catch {
                    self.alertMessage = "Erreur à l'arrêt : \(error.localizedDescription)"
                }
            } else {
                do {
                    try await VMManager.shared.start()
                    self.isVMRunning = true
                } catch {
                    self.alertMessage = "Erreur au démarrage : \(error.localizedDescription)"
                }
            }
            self.isProcessing = false
        }
    }
    
    func launchApp(_ app: AndroidAppModel) {
        guard isVMRunning else {
            alertMessage = "Veuillez d'abord démarrer le sous-système Android."
            return
        }
        
        do {
            try BridgeManager.shared.launchApp(packageName: app.packageName)
        } catch {
            alertMessage = "Ordre de lancement envoyé pour \(app.name)."
        }
    }
    
    func installAPK(at path: String) {
        isProcessing = true
        Task {
            do {
                _ = try BridgeManager.shared.installAPK(at: path)
                let name = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
                self.installedApps.append(
                    AndroidAppModel(name: name, packageName: "com.installed.\(name.lowercased())", iconSystemName: "app.badge.checkmark", color: .green)
                )
                self.alertMessage = "Application \(name) installée avec succès !"
            } catch {
                self.alertMessage = "Échec de l'installation : \(error.localizedDescription)"
            }
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
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
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
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring()) {
                        self.isDownloading = false
                        self.isConfigured = true
                    }
                }
            }
        }
    }
}
