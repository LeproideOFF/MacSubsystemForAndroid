import SwiftUI
import MSACore

struct SetupWizardView: View {
    @ObservedObject var vm: AppViewModel
    
    let androidVersions = [
        (6, "Marshmallow"), (7, "Nougat"), (8, "Oreo"), (9, "Pie"),
        (10, "Android 10"), (11, "Android 11"), (12, "Android 12"),
        (13, "Tiramisu"), (14, "Upside Down Cake"), (15, "Vanilla"),
        (16, "Baklava"), (17, "Preview")
    ]
    
    var body: some View {
        ZStack {
            // Background Liquid Mesh
            RadialGradient(
                colors: [Color.green.opacity(0.15), Color.blue.opacity(0.10), Color.clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 700
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 64, height: 64)
                            .shadow(color: .green.opacity(0.4), radius: 12, y: 6)
                        Image(systemName: "candybarphone")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Mac Subsystem for Android")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    
                    Text("Configurez votre environnement Android natif pour Apple Silicon")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                if vm.isDownloading {
                    // Animated Download & Setup State
                    VStack(spacing: 20) {
                        Spacer()
                        
                        ProgressView(value: vm.downloadProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            .frame(width: 400)
                            .scaleEffect(y: 1.5)
                        
                        Text("\(Int(vm.downloadProgress * 100))%")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                        
                        Text(vm.downloadStatusText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .transition(.opacity)
                        
                        Spacer()
                    }
                    .frame(height: 280)
                    .frame(maxWidth: 550)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                } else {
                    // Settings Form Cards
                    VStack(spacing: 16) {
                        // 1. Version Picker
                        HStack {
                            Label("Version d'Android", systemImage: "sparkles")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                            Picker("", selection: $vm.selectedVersion) {
                                ForEach(androidVersions, id: \.0) { item in
                                    Text("Android \(item.0) (\(item.1))").tag(item.0)
                                }
                            }
                            .frame(width: 220)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        
                        // 2. CPU allocation
                        HStack {
                            Label("Processeurs CPU (ARM64)", systemImage: "cpu")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                            Picker("", selection: $vm.cpuCount) {
                                Text("2 Cœurs").tag(2)
                                Text("4 Cœurs (Optimal)").tag(4)
                                Text("6 Cœurs").tag(6)
                                Text("8 Cœurs (Performance)").tag(8)
                            }
                            .frame(width: 220)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        
                        // 3. RAM allocation
                        HStack {
                            Label("Mémoire RAM", systemImage: "memorychip")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                            Picker("", selection: $vm.ramGB) {
                                Text("2 Go").tag(2)
                                Text("4 Go (Recommandé)").tag(4)
                                Text("6 Go").tag(6)
                                Text("8 Go (Gaming / Lourd)").tag(8)
                            }
                            .frame(width: 220)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        
                        // 4. Google Services Switch
                        HStack {
                            Label("Google Play Store & Services", systemImage: "cart.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                            Text("Inclus & Activé")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.15))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }
                    .frame(maxWidth: 550)
                    
                    // Bouton de validation
                    Button(action: {
                        withAnimation(.spring()) {
                            vm.startInitialSetup()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Télécharger & Déployer Android \(vm.selectedVersion)")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: 550)
                        .padding(.vertical, 13)
                        .background(
                            LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(14)
                        .shadow(color: .green.opacity(0.4), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(28)
        }
    }
}
