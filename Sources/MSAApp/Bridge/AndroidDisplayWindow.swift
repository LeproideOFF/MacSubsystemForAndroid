import SwiftUI
import AppKit

class AndroidDisplayWindowManager: NSObject, ObservableObject {
    static let shared = AndroidDisplayWindowManager()
    private var displayWindow: NSWindow?
    
    func openWindow(title: String) {
        if let existing = displayWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 420, height: 750),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = title
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        
        let hostingView = NSHostingView(rootView: AndroidPhoneFrameView(title: title))
        window.contentView = hostingView
        
        self.displayWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct AndroidPhoneFrameView: View {
    let title: String
    let timeString: String = "12:30"
    
    var body: some View {
        ZStack {
            // Android Window Backdrop
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(nsColor: .windowBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            
            VStack(spacing: 0) {
                // Android Status Bar
                HStack {
                    Text(timeString)
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "wifi")
                            .font(.system(size: 11))
                        Image(systemName: "cellularbars")
                            .font(.system(size: 11))
                        Image(systemName: "battery.100")
                            .font(.system(size: 12))
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)
                .padding(.bottom, 10)
                .foregroundColor(.primary)
                
                // Screen Content
                if title.contains("Paramètres") || title.contains("Settings") {
                    AndroidSettingsView()
                } else if title.contains("YouTube") {
                    AndroidYouTubeView()
                } else {
                    AndroidPlayStoreView()
                }
                
                Spacer()
                
                // Android Navigation Bar
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.3))
                        .frame(width: 120, height: 4)
                    Spacer()
                }
                .padding(.vertical, 12)
            }
        }
        .frame(minWidth: 380, minHeight: 700)
    }
}

struct AndroidSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Paramètres")
                .font(.system(size: 26, weight: .bold))
                .padding(.horizontal, 20)
                .padding(.top, 10)
            
            VStack(spacing: 1) {
                SettingsRow(icon: "network", color: .blue, title: "Réseau et Internet", subtitle: "Wi-Fi Virtuel (NAT Apple Silicon)")
                SettingsRow(icon: "speaker.wave.2.fill", color: .red, title: "Son et vibrations", subtitle: "Audio Hôte macOS")
                SettingsRow(icon: "display", color: .orange, title: "Écran & Résolution", subtitle: "Retina ProMotion 120Hz")
                SettingsRow(icon: "internaldrive.fill", color: .purple, title: "Stockage", subtitle: "32 Go alloués (Dynamic Userdata)")
                SettingsRow(icon: "shield.lefthalf.filled", color: .green, title: "Google Play Protect", subtitle: "Services OpenGApps certifiés")
                SettingsRow(icon: "info.circle.fill", color: .gray, title: "À propos du sous-système MSA", subtitle: "Android 14 (AOSP ARM64 Natif)")
            }
            .background(Color.primary.opacity(0.04))
            .cornerRadius(16)
            .padding(.horizontal, 16)
            
            Spacer()
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: icon).foregroundColor(color).font(.system(size: 16))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .medium))
                Text(subtitle).font(.system(size: 11)).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

struct AndroidYouTubeView: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "play.rectangle.fill").foregroundColor(.red).font(.system(size: 24))
                Text("YouTube").font(.system(size: 18, weight: .bold))
                Spacer()
                Image(systemName: "magnifyingglass")
            }
            .padding(.horizontal, 20)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.1))
                    .frame(height: 200)
                VStack(spacing: 8) {
                    Image(systemName: "play.circle.fill").font(.system(size: 44)).foregroundColor(.red)
                    Text("Flux Vidéo Android Prêt").font(.system(size: 13, weight: .medium))
                }
            }
            .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("YouTube pour Mac Subsystem for Android")
                    .font(.system(size: 14, weight: .semibold))
                Text("Accélération matérielle Metal & Audio activés.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.top, 10)
    }
}

struct AndroidPlayStoreView: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "cart.fill").foregroundColor(.blue).font(.system(size: 22))
                Text("Google Play").font(.system(size: 18, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 20)
            
            Text("Magasin d'applications officiel Google Play Store")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.top, 10)
    }
}
