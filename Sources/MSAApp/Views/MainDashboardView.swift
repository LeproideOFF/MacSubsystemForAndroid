import SwiftUI
import MSACore

struct MainDashboardView: View {
    @StateObject private var vm = AppViewModel()
    
    var body: some View {
        DashboardContent(vm: vm)
            .alert(isPresented: Binding(
                get: { vm.alertMessage != nil },
                set: { if !$0 { vm.alertMessage = nil } }
            )) {
                Alert(title: Text("Mac Subsystem for Android 16"), message: Text(vm.alertMessage ?? ""), dismissButton: .default(Text("OK")))
            }
    }
}

struct DashboardContent: View {
    @ObservedObject var vm: AppViewModel
    
    var body: some View {
        NavigationSplitView {
            // Sidebar Liquid Glass
            VStack(alignment: .leading, spacing: 14) {
                // Header Profil
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        Image(systemName: "ipad.landscape")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Android 16 Subsystem")
                            .font(.system(size: 14, weight: .bold))
                        Text("Format Tablette • ARM64")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, 16)
                
                Divider().opacity(0.3).padding(.horizontal, 16)
                
                // Status & Ping 20s Pill
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(vm.isHeartbeatActive ? Color.green : Color.orange)
                            .frame(width: 9, height: 9)
                            .shadow(color: vm.isHeartbeatActive ? .green : .orange, radius: 4)
                        Text(vm.isHeartbeatActive ? "Sous-système Actif" : "En veille / Arrêté")
                            .font(.system(size: 12, weight: .semibold))
                        Spacer()
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.horizontal.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(vm.isHeartbeatActive ? .green : .secondary)
                        Text(vm.lastPingTime)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .padding(.horizontal, 16)
                
                // Navigation Buttons (Applications, Personnalisation Appareil, Performances & Thermique)
                VStack(spacing: 4) {
                    SidebarNavButton(icon: "square.grid.2x2.fill", title: "Applications", isSelected: vm.activeTab == "apps") {
                        vm.activeTab = "apps"
                    }
                    SidebarNavButton(icon: "iphone.and.arrow.forward", title: "Format & Appareil", isSelected: vm.activeTab == "device") {
                        vm.activeTab = "device"
                    }
                    SidebarNavButton(icon: "cpu.fill", title: "Performances & Éco", isSelected: vm.activeTab == "perf") {
                        vm.activeTab = "perf"
                    }
                    SidebarNavButton(icon: "terminal.fill", title: "Console & Logs", isSelected: vm.activeTab == "logs") {
                        vm.activeTab = "logs"
                    }
                    SidebarNavButton(icon: "arrow.down.doc.fill", title: "Installer un APK", isSelected: false) {
                        selectAndInstallAPK()
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 6)
                
                Spacer()
                
                // Bouton Installer Android 16 (affiché UNIQUEMENT si non encore installé)
                if !vm.isConfigured {
                    Button(action: {
                        vm.installAndroidSubsystem()
                    }) {
                        HStack {
                            if vm.isInstallingSubsystem {
                                ProgressView()
                                    .controlSize(.small)
                                    .colorInvert()
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                            }
                            Text(vm.isInstallingSubsystem ? "Configuration..." : "Installer Android 16")
                                .fontWeight(.medium)
                                .font(.system(size: 12))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.85))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isInstallingSubsystem)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                }
                
                // Bouton Start / Stop Bare Metal
                Button(action: {
                    vm.toggleVM()
                }) {
                    HStack {
                        if vm.isProcessing {
                            ProgressView()
                                .controlSize(.small)
                                .colorInvert()
                        } else {
                            Image(systemName: vm.isVMRunning ? "stop.fill" : "play.fill")
                        }
                        Text(vm.isVMRunning ? "Arrêter Android 16" : "Démarrer Android 16")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(vm.isVMRunning ? Color.red.opacity(0.85) : Color.green.opacity(0.85))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 4)
                }
                .buttonStyle(.plain)
                .disabled(vm.isProcessing)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(minWidth: 230, maxWidth: 250)
            .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
        } detail: {
            // Main Content Area Liquid Glass
            ZStack {
                RadialGradient(
                    colors: [Color.green.opacity(0.08), Color.blue.opacity(0.05), Color.clear],
                    center: .topTrailing,
                    startRadius: 10,
                    endRadius: 500
                )
                
                VStack(alignment: .leading, spacing: 18) {
                    // Top Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sous-Système Android 16")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                            Text("Apple Silicon ARM64 • Fenêtres Natives Découplées & Écran d'Accueil")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: selectAndInstallAPK) {
                            Label("Ajouter un APK", systemImage: "plus.circle.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    
                    // Zone APK Interactive ou Barre de Progression d'Installation
                    if vm.isInstallingAPK {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Installation en cours...", systemImage: "arrow.down.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.green)
                                Spacer()
                                Text("\(Int(vm.apkInstallProgress * 100))%")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                            }
                            
                            ProgressView(value: vm.apkInstallProgress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            
                            HStack {
                                Text(vm.apkInstallStatus)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        .padding(18)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 28)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Onglets de Contenu
                    if vm.activeTab == "apps" {
                        AppsTabView(vm: vm)
                    } else if vm.activeTab == "device" {
                        DeviceCustomizationView(vm: vm)
                    } else if vm.activeTab == "perf" {
                        PerformanceTabView(vm: vm)
                    } else if vm.activeTab == "logs" {
                        AndroidLogsTabView(vm: vm)
                    }
                }
            }
        }
    }
    
    func selectAndInstallAPK() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = []
        
        if panel.runModal() == .OK, let url = panel.url {
            vm.installAPK(at: url.path)
        }
    }
}

struct AppsTabView: View {
    @ObservedObject var vm: AppViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Drag and Drop Zone APK
            if !vm.isInstallingAPK {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(
                                    vm.isDraggingOver ? Color.green : Color.white.opacity(0.2),
                                    style: StrokeStyle(lineWidth: 1.5, dash: [6])
                                )
                        )
                    
                    VStack(spacing: 6) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                        Text("Glissez-déposez un fichier APK ici")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Installez vos APKs sans passer par l'interface lourde")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 14)
                }
                .padding(.horizontal, 28)
                .onDrop(of: ["public.file-url"], isTargeted: $vm.isDraggingOver) { providers in
                    guard let provider = providers.first else { return false }
                    provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { urlData, _ in
                        if let data = urlData as? Data,
                           let path = URL(dataRepresentation: data, relativeTo: nil)?.path {
                            DispatchQueue.main.async {
                                vm.installAPK(at: path)
                            }
                        }
                    }
                    return true
                }
            }
            
            HStack {
                Text("Applications Android 16")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Text("Clic = Fenêtre native macOS dédiée")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 28)
            .padding(.top, 4)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                    ForEach(vm.installedApps) { app in
                        Button(action: {
                            vm.launchApp(app)
                        }) {
                            RealAppCardView(app: app)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
    }
}

struct DeviceCustomizationView: View {
    @ObservedObject var vm: AppViewModel
    
    let presets = ["Pixel Phone", "Tablette (Grand Écran)", "Compact (Mini Fenêtre)", "Libre / Personnalisé"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Personnalisation de l'Appareil & Résolution")
                        .font(.system(size: 18, weight: .bold))
                    Text("Adaptez la taille et la densité d'affichage des fenêtres natives de vos applications.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Presets
                VStack(alignment: .leading, spacing: 12) {
                    Text("Profils d'appareil prédéfinis")
                        .font(.system(size: 14, weight: .semibold))
                    
                    HStack(spacing: 12) {
                        ForEach(presets, id: \.self) { preset in
                            Button(action: {
                                vm.applyPreset(preset)
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: preset.contains("Phone") ? "iphone" : (preset.contains("Tablette") ? "ipad" : "macwindow"))
                                        .font(.system(size: 20))
                                    Text(preset)
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(vm.selectedDevicePreset == preset ? Color.green.opacity(0.18) : Color.white.opacity(0.06))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(vm.selectedDevicePreset == preset ? Color.green : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(18)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                
                // Sliders de redimensionnement dynamique
                VStack(alignment: .leading, spacing: 16) {
                    Text("Dimensions & Densité sur mesure")
                        .font(.system(size: 14, weight: .semibold))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Largeur de fenêtre :")
                            Spacer()
                            Text("\(vm.customWidth) px")
                                .fontWeight(.bold)
                                .font(.system(size: 13, design: .monospaced))
                        }
                        Slider(value: Binding(
                            get: { Double(vm.customWidth) },
                            set: { vm.customWidth = Int($0) }
                        ), in: 320...1200, step: 20)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Hauteur de fenêtre :")
                            Spacer()
                            Text("\(vm.customHeight) px")
                                .fontWeight(.bold)
                                .font(.system(size: 13, design: .monospaced))
                        }
                        Slider(value: Binding(
                            get: { Double(vm.customHeight) },
                            set: { vm.customHeight = Int($0) }
                        ), in: 480...1600, step: 20)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Densité d'affichage (DPI) :")
                            Spacer()
                            Text("\(vm.customDensity) dpi")
                                .fontWeight(.bold)
                                .font(.system(size: 13, design: .monospaced))
                        }
                        Slider(value: Binding(
                            get: { Double(vm.customDensity) },
                            set: { vm.customDensity = Int($0) }
                        ), in: 160...480, step: 20)
                    }
                    
                    Button(action: {
                        vm.applyPreset("Libre / Personnalisé")
                        BridgeManager.shared.setDisplayResolution(width: vm.customWidth, height: vm.customHeight, density: vm.customDensity)
                        vm.alertMessage = "Dimensions appliquées : \(vm.customWidth)x\(vm.customHeight) @ \(vm.customDensity) DPI !"
                    }) {
                        Label("Appliquer à l'affichage actif", systemImage: "arrow.triangle.2.circlepath")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.green.opacity(0.85))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(18)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                
                // Gestion & Maintenance du Sous-Système (Réinstaller / Supprimer)
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundColor(.orange)
                        Text("Gestion & Maintenance du Sous-Système")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    
                    Text("Vous pouvez réinitialiser complètement l'environnement Android 16 ou supprimer les partitions de données pour repartir de zéro.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            vm.reinstallSubsystem()
                        }) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            Text("Tout Réinstaller")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.85))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            vm.deleteSubsystem()
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                            }
                            Text("Supprimer le Sous-Système")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.85))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
    }
}

struct PerformanceTabView: View {
    @ObservedObject var vm: AppViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Performances & Gestion Thermique Apple Silicon")
                        .font(.system(size: 18, weight: .bold))
                    Text("Surveillance en direct de l'impact matériel et optimisation thermique pour éviter la chauffe.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Carte Mode Éco / Zéro Chauffe
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(vm.ecoModeEnabled ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                            .frame(width: 50, height: 50)
                        Image(systemName: vm.ecoModeEnabled ? "snowflake" : "flame.fill")
                            .font(.system(size: 26))
                            .foregroundColor(vm.ecoModeEnabled ? .blue : .orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.ecoModeEnabled ? "Mode Éco Silencieux Activé" : "Mode Standard")
                            .font(.system(size: 15, weight: .bold))
                        Text(vm.ecoModeEnabled ? "Animations Android désactivées, consommation GPU bridée pour un Mac parfaitement froid." : "Fréquence et animations maximales.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        vm.toggleEcoMode()
                    }) {
                        Text(vm.ecoModeEnabled ? "Désactiver" : "Activer")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(vm.ecoModeEnabled ? Color.blue : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(18)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(vm.ecoModeEnabled ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                )
                
                // Sélecteurs de Fluidité Matérielle ProMotion & Metal
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "speedometer")
                            .foregroundColor(.blue)
                        Text("Affichage Direct Bare Metal (Sans Flux Vidéo)")
                            .font(.system(size: 15, weight: .bold))
                    }
                    
                    // Sélecteur de Fréquence FPS
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Taux de rafraîchissement d'écran ProMotion (FPS) :")
                            .font(.system(size: 13, weight: .medium))
                        
                        HStack(spacing: 8) {
                            ForEach([30, 60, 90, 120, 144], id: \.self) { fps in
                                Button(action: {
                                    vm.selectedMaxFps = fps
                                }) {
                                    Text("\(fps) FPS\(fps == 120 ? " ⚡ ProMotion" : "")")
                                        .font(.system(size: 12, weight: vm.selectedMaxFps == fps ? .bold : .regular))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(vm.selectedMaxFps == fps ? Color.blue : Color.white.opacity(0.08))
                                        .foregroundColor(vm.selectedMaxFps == fps ? .white : .primary)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 13))
                        Text("Rendu mémoire directe Metal / VZScanout — Aucun flux vidéo ni compression de codec.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
                .padding(18)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                
                // Métriques en Direct
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    MetricTileView(
                        icon: "cpu",
                        title: "Charge Processeur",
                        value: vm.cpuUsageText,
                        subtext: "Apple Silicon AArch64 Natif",
                        tint: .green
                    )
                    
                    MetricTileView(
                        icon: "thermometer.snowflake",
                        title: "Température Sous-système",
                        value: vm.thermalTempText,
                        subtext: "Gestion adaptative de puissance",
                        tint: .blue
                    )
                    
                    MetricTileView(
                        icon: "memorychip",
                        title: "Mémoire Vive Utilisée",
                        value: vm.ramUsageText,
                        subtext: "Partagée dynamiquement",
                        tint: .purple
                    )
                    
                    MetricTileView(
                        icon: "gauge.with.needle",
                        title: "Accélération Graphique",
                        value: "Metal Vulkan Portability",
                        subtext: "Rendu GPU direct sans émulation x86",
                        tint: .orange
                    )
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
    }
}

struct MetricTileView: View {
    let icon: String
    let title: String
    let value: String
    let subtext: String
    let tint: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(tint)
                    .font(.system(size: 18))
                Spacer()
            }
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .lineLimit(1)
            
            Text(subtext)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.03), radius: 6, y: 3)
    }
}

struct SidebarNavButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .green : .secondary)
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isSelected ? Color.green.opacity(0.12) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct RealAppCardView: View {
    let app: AppViewModel.AndroidAppModel
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [app.color.opacity(0.8), app.color.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .shadow(color: app.color.opacity(0.3), radius: 6, y: 3)
                
                Image(systemName: app.iconSystemName)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 2) {
                Text(app.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                
                Text(app.isHomeLauncher ? "Bureau Pixel" : "Fenêtre macOS")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}

struct AndroidLogsTabView: View {
    @ObservedObject var vm: AppViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Journal & Console Android 16 en Direct")
                        .font(.system(size: 18, weight: .bold))
                    Text("Nettoyage automatique permanent (tampon 300 lignes max) • Zéro lag")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: {
                    vm.clearLogs()
                }) {
                    Label("Effacer", systemImage: "trash")
                        .font(.system(size: 12))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
            .padding(.top, 4)
            
            // Terminal Log Viewer
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(vm.androidLogs.enumerated()), id: \.offset) { index, logLine in
                            Text(logLine)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(
                                    logLine.contains("❌") ? .red :
                                    (logLine.contains("✅") ? .green :
                                    (logLine.contains("🚀") ? .blue : .white.opacity(0.85)))
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(index)
                        }
                    }
                    .padding(14)
                }
                .background(Color.black.opacity(0.65))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
                .onChange(of: vm.androidLogs.count) { _ in
                    if let lastIndex = vm.androidLogs.indices.last {
                        proxy.scrollTo(lastIndex, anchor: .bottom)
                    }
                }
            }
        }
    }
}
