import SwiftUI
import MSACore

class DashboardState: ObservableObject {
    @Published var isVMRunning: Bool = false
    @Published var selectedVersion: Int = 14
    @Published var installedApps: [String] = ["Google Play Store", "TikTok", "WhatsApp", "Instagram"]
    @Published var isDraggingOver: Bool = false
}

struct MainDashboardView: View {
    @StateObject private var state = DashboardState()
    let versions = [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
    
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
                        Text("Android Subsystem")
                            .font(.system(size: 14, weight: .bold))
                        Text("Apple Silicon ARM64")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, 16)
                
                Divider().opacity(0.3).padding(.horizontal, 16)
                
                // Status Pill
                HStack(spacing: 8) {
                    Circle()
                        .fill(state.isVMRunning ? Color.green : Color.orange)
                        .frame(width: 9, height: 9)
                        .shadow(color: state.isVMRunning ? .green : .orange, radius: 4)
                    Text(state.isVMRunning ? "Sous-système Actif" : "En veille / Arrêté")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .padding(.horizontal, 16)
                
                // Menu List
                VStack(spacing: 4) {
                    SidebarButton(icon: "square.grid.2x2.fill", title: "Mes Applications", isSelected: true)
                    SidebarButton(icon: "arrow.down.circle.fill", title: "Installation APK", isSelected: false)
                    SidebarButton(icon: "gearshape.fill", title: "Performances & RAM", isSelected: false)
                }
                .padding(.horizontal, 8)
                .padding(.top, 10)
                
                Spacer()
                
                // Bouton Start / Stop
                Button(action: toggleVM) {
                    HStack {
                        Image(systemName: state.isVMRunning ? "stop.fill" : "play.fill")
                        Text(state.isVMRunning ? "Arrêter MSA" : "Démarrer MSA")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(state.isVMRunning ? Color.red.opacity(0.85) : Color.green.opacity(0.85))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 4)
                }
                .buttonStyle(.plain)
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
                            Text("Sous-Système Android")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                            Text("Exécution native sans émulateur pour macOS")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Sélecteur de version Liquid Glass
                        HStack(spacing: 8) {
                            Text("Version :")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Picker("", selection: $state.selectedVersion) {
                                ForEach(versions, id: \.self) { v in
                                    Text("Android \(v)").tag(v)
                                }
                            }
                            .frame(width: 130)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    
                    // Drag and Drop Zone APK
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(
                                        state.isDraggingOver ? Color.green : Color.white.opacity(0.2),
                                        style: StrokeStyle(lineWidth: 1.5, dash: [6])
                                    )
                            )
                        
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.green)
                            Text("Glissez-déposez un fichier APK ici")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Installation instantanée et intégration dans Spotlight")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 20)
                    }
                    .padding(.horizontal, 28)
                    
                    // Applications Grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Applications Installées")
                            .font(.system(size: 16, weight: .bold))
                            .padding(.horizontal, 28)
                        
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                                ForEach(state.installedApps, id: \.self) { app in
                                    AppCardView(title: app)
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
    
    func toggleVM() {
        withAnimation(.spring()) {
            state.isVMRunning.toggle()
        }
    }
}

struct SidebarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    
    var body: some View {
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
}

struct AppCardView: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [.white.opacity(0.15), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
                
                Image(systemName: "app.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.green)
            }
            
            Text(title)
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
