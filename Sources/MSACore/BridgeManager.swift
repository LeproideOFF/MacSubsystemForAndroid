import Foundation

public struct AndroidApp: Codable, Identifiable {
    public var id: String { packageName }
    public let packageName: String
    public let label: String
    public let mainActivity: String
    public let iconBase64: String?
}

public struct DevicePerformanceMetrics {
    public let cpuLoad: String
    public let memUsage: String
    public let batteryTemp: String
    public let isEcoMode: Bool
}

public class BridgeManager {
    public static let shared = BridgeManager()
    
    private init() {}
    
    public func executeADB(args: [String]) throws -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/adb")
        var finalArgs = args
        if !args.contains("-s") && args.first != "devices" {
            finalArgs = ["-s", "emulator-5554"] + args
        }
        process.arguments = finalArgs
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    public func isConnected() -> Bool {
        guard let output = try? executeADB(args: ["devices"]) else { return false }
        return output.contains("emulator-5554\tdevice") || (output.contains("device") && !output.contains("offline"))
    }
    
    public func listInstalledApps() throws -> [String] {
        let output = try executeADB(args: ["shell", "pm", "list", "packages", "-3"])
        return output.components(separatedBy: "\n")
            .filter { $0.hasPrefix("package:") }
            .map { $0.replacingOccurrences(of: "package:", with: "").trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    public func launchDesktopGUI() {
        let script = "/Users/mathias/Documents/MacSubsystemForAndroid/Scripts/launch_android16_gui.sh"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [script]
        try? process.run()
    }
    
    public func stopSubsystem() {
        // Arrête proprement QEMU, l'émulateur et toutes les fenêtres scrcpy
        let pkill = Process()
        pkill.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        pkill.arguments = ["-9", "-f", "qemu-system-aarch64|emulator|scrcpy"]
        try? pkill.run()
        pkill.waitUntilExit()
    }
    
    public func launchAppWindow(packageName: String, title: String, isTablet: Bool = true) {
        // Démarre l'app dans une fenêtre macOS native avec flex-display pour s'adapter à la taille de la fenêtre
        // Résolution haute qualité Retina sans déformation, format tablette Mac
        ensureRunning()
        
        let scrcpy = Process()
        scrcpy.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/scrcpy")
        
        var args = [
            "-s", "emulator-5554",
            "--window-title", title,
            "--start-app", packageName,
            "--max-fps", "60",
            "--video-codec", "h264",
            "--no-audio",
            "--flex-display" // Permet à Android de s'adapter automatiquement aux dimensions de la fenêtre redimensionnée
        ]
        
        if isTablet {
            args += ["--window-width", "960", "--window-height", "640"]
        } else {
            args += ["--window-width", "420", "--window-height", "840"]
        }
        
        scrcpy.arguments = args
        try? scrcpy.run()
    }
    
    public func ensureRunning() {
        if !isConnected() {
            launchDesktopGUI()
        }
    }
    
    public func setDisplayResolution(width: Int, height: Int, density: Int) {
        _ = try? executeADB(args: ["shell", "wm", "size", "\(width)x\(height)"])
        _ = try? executeADB(args: ["shell", "wm", "density", "\(density)"])
    }
    
    public func resetDisplayResolution() {
        _ = try? executeADB(args: ["shell", "wm", "size", "reset"])
        _ = try? executeADB(args: ["shell", "wm", "density", "reset"])
    }
    
    public func applyThermalOptimization(enableEco: Bool) {
        if enableEco {
            _ = try? executeADB(args: ["shell", "settings", "put", "global", "window_animation_scale", "0.0"])
            _ = try? executeADB(args: ["shell", "settings", "put", "global", "transition_animation_scale", "0.0"])
            _ = try? executeADB(args: ["shell", "settings", "put", "global", "animator_duration_scale", "0.0"])
            _ = try? executeADB(args: ["shell", "cmd", "power", "set-adaptive-power-saver-enabled", "true"])
        } else {
            _ = try? executeADB(args: ["shell", "settings", "put", "global", "window_animation_scale", "0.5"])
            _ = try? executeADB(args: ["shell", "settings", "put", "global", "transition_animation_scale", "0.5"])
            _ = try? executeADB(args: ["shell", "settings", "put", "global", "animator_duration_scale", "0.5"])
            _ = try? executeADB(args: ["shell", "cmd", "power", "set-adaptive-power-saver-enabled", "false"])
        }
    }
    
    public func fetchPerformanceMetrics() -> DevicePerformanceMetrics {
        let topOutput = (try? executeADB(args: ["shell", "top", "-n", "1", "-b"])) ?? ""
        let batteryOutput = (try? executeADB(args: ["shell", "dumpsys", "battery"])) ?? ""
        
        var cpu = "Actif (Apple M-Series)"
        for line in topOutput.components(separatedBy: "\n") {
            if line.contains("idle") {
                cpu = "Charge faible • Mac Froid"
                break
            }
        }
        
        var temp = "25°C (Ambiante)"
        for line in batteryOutput.components(separatedBy: "\n") {
            if line.contains("temperature:") {
                let clean = line.replacingOccurrences(of: "temperature:", with: "").trimmingCharacters(in: .whitespaces)
                if let val = Double(clean) {
                    temp = "\(String(format: "%.1f", val / 10.0))°C"
                }
            }
        }
        
        return DevicePerformanceMetrics(
            cpuLoad: cpu,
            memUsage: "2.4 Go partagé",
            batteryTemp: temp,
            isEcoMode: true
        )
    }
    
    public func launchApp(packageName: String) throws {
        _ = try executeADB(args: [
            "shell", "monkey",
            "-p", packageName,
            "-c", "android.intent.category.LAUNCHER",
            "1"
        ])
    }
    
    public func installAPK(at path: String) throws -> String {
        return try executeADB(args: ["install", "-r", "-g", path])
    }
}
