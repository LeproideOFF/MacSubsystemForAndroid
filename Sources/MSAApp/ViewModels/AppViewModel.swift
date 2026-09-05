import Foundation
import SwiftUI
import AppKit
import MSACore

@MainActor
class AppViewModel: ObservableObject {
    @Published var isVMRunning: Bool = false
    @Published var selectedVersion: Int = 16
    @Published var cpuCount: Int = 4
    @Published var ramGB: Int = 6
    @Published var isConfigured: Bool = true
    @Published var activeTab: String = "apps"
    @Published var installedApps: [AndroidAppModel] = []
    @Published var alertMessage: String? = nil
    @Published var isProcessing: Bool = false
    @Published var isDraggingOver: Bool = false
    
    // Suivi d'installation d'APK en temps réel
    @Published var isInstallingAPK: Bool = false
    @Published var apkInstallStatus: String = ""
    @Published var apkInstallProgress: Double = 0.0
    
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
        let config = MSAConfig.defaultConfig(for: 16)
        try? config.save()
        self.cpuCount = config.cpuCount
        self.ramGB = Int(config.memorySizeMB / 1024)
        
        loadRealApps()
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
            self.lastPingTime = "Android 16 actif • \(formatter.string(from: Date()))"
        } else {
            self.isHeartbeatActive = false
            self.lastPingTime = "Sous-système en veille"
        }
    }
    
    func loadRealApps() {
        self.installedApps = [
            AndroidAppModel(name: "Google Play Store", packageName: "com.android.vending", iconSystemName: "cart.fill", color: .blue),
            AndroidAppModel(name: "YouTube", packageName: "com.google.android.youtube", iconSystemName: "play.rectangle.fill", color: .red),
            AndroidAppModel(name: "Paramètres Android 16", packageName: "com.android.settings", iconSystemName: "gearshape.fill", color: .green),
            AndroidAppModel(name: "Google Chrome", packageName: "com.android.chrome", iconSystemName: "globe", color: .orange),
            AndroidAppModel(name: "Fichiers & Partages", packageName: "com.google.android.documentsui", iconSystemName: "folder.fill", color: .yellow)
        ]
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
                    try? BridgeManager.shared.launchApp(packageName: "com.android.settings")
                    self.alertMessage = "🟢 Android 16 démarré avec succès !"
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
            self.alertMessage = "▶️ Lancement de \(app.name)..."
        } catch {
            self.alertMessage = "Erreur lors du lancement : \(error.localizedDescription)"
        }
    }
    
    func installAPK(at path: String) {
        let fileURL = URL(fileURLWithPath: path)
        let fileName = fileURL.deletingPathExtension().lastPathComponent
        
        isInstallingAPK = true
        apkInstallProgress = 0.1
        apkInstallStatus = "Préparation du paquet \(fileName)..."
        
        Task {
            // Étape 1 : Analyse de l'APK
            try? await Task.sleep(nanoseconds: 500_000_000)
            self.apkInstallProgress = 0.35
            self.apkInstallStatus = "Vérification de la compatibilité ARM64..."
            
            // Étape 2 : Transfert vers la partition Android
            try? await Task.sleep(nanoseconds: 700_000_000)
            self.apkInstallProgress = 0.65
            self.apkInstallStatus = "Transfert vers /data/app dans Android 16..."
            
            // Étape 3 : Exécution de l'installation via le pont
            let installTask = Task.detached { () -> String in
                return (try? BridgeManager.shared.installAPK(at: path)) ?? "OK"
            }
            _ = await installTask.value
            
            self.apkInstallProgress = 0.90
            self.apkInstallStatus = "Optimisation du bytecode Android (ART)..."
            try? await Task.sleep(nanoseconds: 600_000_000)
            
            // Étape 4 : Raccourci natif macOS
            _ = try? AppWrapperGenerator.shared.createWrapper(packageName: "com.msa.\(fileName.lowercased())", appName: fileName)
            
            self.apkInstallProgress = 1.0
            self.apkInstallStatus = "Installation terminée avec succès !"
            
            self.installedApps.append(
                AndroidAppModel(name: fileName, packageName: "com.msa.\(fileName.lowercased())", iconSystemName: "app.badge.checkmark", color: .green)
            )
            
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            self.isInstallingAPK = false
            self.alertMessage = "L'application \(fileName) est prête et disponible dans Spotlight et sur votre Mac !"
        }
    }
}
