import Foundation

public struct MSAConfig: Codable {
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

    public static var defaultConfig: MSAConfig {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let msaHome = "\(home)/.msa"
        return MSAConfig(
            cpuCount: max(2, ProcessInfo.processInfo.processorCount / 2),
            memorySizeMB: 4096,
            diskSizeGB: 32,
            kernelPath: "\(msaHome)/images/vmlinux-arm64",
            initrdPath: "\(msaHome)/images/initrd.img",
            diskImagePath: "\(msaHome)/images/userdata.img",
            systemImagePath: "\(msaHome)/images/system.img",
            dataDirectory: msaHome,
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
            return defaultConfig
        }
        return decoded
    }

    public func save() throws {
        let dirUrl = URL(fileURLWithPath: dataDirectory)
        try FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true)
        let configPath = "\(dataDirectory)/config.json"
        let data = try JSONEncoder().encode(self)
        try data.write(to: URL(fileURLWithPath: configPath))
    }
}
