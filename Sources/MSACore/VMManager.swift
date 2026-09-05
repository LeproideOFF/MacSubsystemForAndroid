import Foundation
import Virtualization

public enum VMState {
    case stopped
    case starting
    case running
    case pausing
    case paused
    case error(String)
}

public protocol VMManagerDelegate: AnyObject {
    func vmStateChanged(to state: VMState)
}

public class VMManager: NSObject, VZVirtualMachineDelegate {
    public static let shared = VMManager()
    
    public private(set) var state: VMState = .stopped {
        didSet {
            delegate?.vmStateChanged(to: state)
        }
    }
    
    public weak var delegate: VMManagerDelegate?
    private var virtualMachine: VZVirtualMachine?
    private var config: MSAConfig = .load()
    
    public override init() {
        super.init()
    }
    
    public func createConfiguration() throws -> VZVirtualMachineConfiguration {
        let vzConfig = VZVirtualMachineConfiguration()
        
        // 1. CPU & Memory
        vzConfig.cpuCount = min(config.cpuCount, VZVirtualMachineConfiguration.maximumAllowedCPUCount)
        let memoryBytes = config.memorySizeMB * 1024 * 1024
        vzConfig.memorySize = max(VZVirtualMachineConfiguration.minimumAllowedMemorySize,
                                  min(memoryBytes, VZVirtualMachineConfiguration.maximumAllowedMemorySize))
        
        // 2. Linux / Android Bootloader
        let bootLoader = VZLinuxBootLoader(kernelURL: URL(fileURLWithPath: config.kernelPath))
        if FileManager.default.fileExists(atPath: config.initrdPath) {
            bootLoader.initialRamdiskURL = URL(fileURLWithPath: config.initrdPath)
        }
        
        // Kernel command line for Android AOSP ARM64
        bootLoader.commandLine = [
            "console=hvc0",
            "root=/dev/vda",
            "rw",
            "androidboot.hardware=virtio",
            "androidboot.selinux=permissive",
            "androidboot.freeform_window_management=1",
            "init=/init",
            "quiet"
        ].joined(separator: " ")
        vzConfig.bootLoader = bootLoader
        
        // 3. Serial Console (HVC0)
        let serial = VZVirtioConsoleDeviceSerialPortConfiguration()
        let stdioPipe = Pipe()
        let serialPortAttachment = VZFileHandleSerialPortAttachment(
            fileHandleForReading: FileHandle.standardInput,
            fileHandleForWriting: stdioPipe.fileHandleForWriting
        )
        serial.attachment = serialPortAttachment
        vzConfig.serialPorts = [serial]
        
        // 4. Block Devices (Disks)
        var storageDevices: [VZStorageDeviceConfiguration] = []
        
        // System Image (Read-Only)
        if FileManager.default.fileExists(atPath: config.systemImagePath) {
            let systemAttachment = try VZDiskImageStorageDeviceAttachment(
                url: URL(fileURLWithPath: config.systemImagePath),
                readOnly: true
            )
            let systemBlock = VZVirtioBlockDeviceConfiguration(attachment: systemAttachment)
            storageDevices.append(systemBlock)
        }
        
        // Userdata Image (Read-Write)
        if FileManager.default.fileExists(atPath: config.diskImagePath) {
            let dataAttachment = try VZDiskImageStorageDeviceAttachment(
                url: URL(fileURLWithPath: config.diskImagePath),
                readOnly: false
            )
            let dataBlock = VZVirtioBlockDeviceConfiguration(attachment: dataAttachment)
            storageDevices.append(dataBlock)
        }
        vzConfig.storageDevices = storageDevices
        
        // 5. Network (Virtio NAT)
        let networkDevice = VZVirtioNetworkDeviceConfiguration()
        networkDevice.attachment = VZNATNetworkDeviceAttachment()
        vzConfig.networkDevices = [networkDevice]
        
        // 6. Sockets (Virtio Vsock for ultra-fast host <-> guest IPC)
        let socketDevice = VZVirtioSocketDeviceConfiguration()
        vzConfig.socketDevices = [socketDevice]
        
        // 7. Entropy (Virtio RNG)
        vzConfig.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]
        
        // Validate
        try vzConfig.validate()
        return vzConfig
    }
    
    public func start() async throws {
        guard case .stopped = state else { return }
        state = .starting
        
        let vzConfig = try createConfiguration()
        let vm = VZVirtualMachine(configuration: vzConfig)
        vm.delegate = self
        self.virtualMachine = vm
        
        try await vm.start()
        state = .running
    }
    
    public func stop() async throws {
        guard let vm = virtualMachine, case .running = state else { return }
        try await vm.stop()
        state = .stopped
    }
    
    // MARK: - VZVirtualMachineDelegate
    public func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        state = .stopped
    }
    
    public func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) {
        state = .error(error.localizedDescription)
    }
}
