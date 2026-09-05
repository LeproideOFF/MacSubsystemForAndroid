import Foundation

public struct AndroidApp: Codable, Identifiable {
    public var id: String { packageName }
    public let packageName: String
    public let label: String
    public let mainActivity: String
    public let iconBase64: String?
}

public class BridgeManager {
    public static let shared = BridgeManager()
    
    private init() {}
    
    public func executeADB(args: [String]) throws -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/adb")
        process.arguments = args
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    public func isConnected() -> Bool {
        guard let output = try? executeADB(args: ["devices"]) else { return false }
        return output.contains("device") && !output.contains("offline")
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
    
    public func launchApp(packageName: String) throws {
        launchDesktopGUI()
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 2.0) {
            _ = try? self.executeADB(args: [
                "shell", "monkey",
                "-p", packageName,
                "-c", "android.intent.category.LAUNCHER",
                "1"
            ])
        }
    }
    
    public func installAPK(at path: String) throws -> String {
        return try executeADB(args: ["install", "-r", "-g", path])
    }
}
