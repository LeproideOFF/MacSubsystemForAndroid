import Foundation

public struct MSAConfig: Codable {
    public var selectedAndroidVersion: Int
    public var cpuCount: Int
    public var memorySizeMB: UInt64
    public var diskSizeGB: Int
    public var kernelPath: String
    public var initrdPath: String
    public var diskImagePath: String
    public var systemImagePath: String
    public var dataDirectory: String
    public var adbPort: Int
    public var enableGApps: Bool
    public var vsockPort: UInt32

    public static func defaultConfig(for version: Int = 13) -> MSAConfig {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let msaHome = "\(home)/.msa"
        let versionDir = "\(msaHome)/android-\(version)"
        return MSAConfig(
            selectedAndroidVersion: version,
            cpuCount: max(2, ProcessInfo.processInfo.processorCount / 2),
            memorySizeMB: 4096,
            diskSizeGB: 32,
            kernelPath: "\(versionDir)/vmlinux-arm64",
            initrdPath: "\(versionDir)/initrd.img",
            diskImagePath: "\(versionDir)/userdata.img",
            systemImagePath: "\(versionDir)/system.img",
            dataDirectory: versionDir,
            adbPort: 5555,
            enableGApps: true,
            vsockPort: 1024
        )
    }

    public static func load() -> MSAConfig {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let configPath = "\(home)/.msa/config.json"
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
              let decoded = try? JSONDecoder().decode(MSAConfig.self, from: data) else {
            return defaultConfig()
        }
        return decoded
    }

    public func save() throws {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let msaRoot = "\(home)/.msa"
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: msaRoot), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: dataDirectory), withIntermediateDirectories: true)
        let configPath = "\(msaRoot)/config.json"
        let data = try JSONEncoder().encode(self)
        try data.write(to: URL(fileURLWithPath: configPath))
    }
}
