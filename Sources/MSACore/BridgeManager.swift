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
        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        // Look for our specific MSA port or valid attached Android device
        for line in lines {
            if (line.contains("127.0.0.1:5555") || line.contains("emulator-") || line.contains("device")) && !line.contains("List of") {
                // Verify it's Android by checking for getprop or pm
                if let test = try? executeADB(args: ["shell", "which", "pm"]), test.contains("pm") {
                    return true
                }
            }
        }
        return false
    }
    
    public func listInstalledApps() throws -> [String] {
        let output = try executeADB(args: ["shell", "pm", "list", "packages", "-3"])
        return output.components(separatedBy: "\n")
            .filter { $0.hasPrefix("package:") }
            .map { $0.replacingOccurrences(of: "package:", with: "").trimmingCharacters(in: .whitespacesAndNewlines) }
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
    
    public func uninstallApp(packageName: String) throws -> String {
        return try executeADB(args: ["uninstall", packageName])
    }
}
