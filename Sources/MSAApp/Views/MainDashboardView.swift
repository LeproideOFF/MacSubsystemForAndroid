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
                            .fill(LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                        Image(systemName: "candybarphone")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Android 16 Subsystem")
                            .font(.system(size: 14, weight: .bold))
                        Text("Google AOSP ARM64")
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
                
                // Navigation Buttons
                VStack(spacing: 4) {
                    SidebarNavButton(icon: "square.grid.2x2.fill", title: "Applications", isSelected: vm.activeTab == "apps") {
                        vm.activeTab = "apps"
                    }
                    SidebarNavButton(icon: "arrow.down.doc.fill", title: "Installer un APK", isSelected: vm.activeTab == "install") {
                        selectAndInstallAPK()
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 10)
                
                Spacer()
                
                // Bouton Start / Stop
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
                .padding(16)
            }
            .frame(minWidth: 220, maxWidth: 240)
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
                
                VStack(alignment: .leading, spacing: 20) {
                    // Top Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sous-Système Android 16")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                            Text("Image Officielle Google AOSP ARM64 (3,5 Go) avec Google Play")
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
                        // Carte de progression en direct
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
                    } else {
                        // Drag and Drop Zone APK
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(
                                            vm.isDraggingOver ? Color.green : Color.white.opacity(0.2),
                                            style: StrokeStyle(lineWidth: 1.5, dash: [6])
                                        )
                                )
                            
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.down.doc.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.green)
                                Text("Glissez-déposez un fichier APK ici")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Affichage de l'avancement détaillé en temps réel")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 18)
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
                    
                    // Applications Grid Réelles
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Applications Android 16")
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                            Text("\(vm.installedApps.count) disponible(s)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 28)
                        
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
            
            Text(app.name)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}
