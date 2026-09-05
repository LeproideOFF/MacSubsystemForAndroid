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
    public var virtualMachine: VZVirtualMachine?
    private var config: MSAConfig = .load()
    
    public override init() {
        super.init()
    }
    
    public func validateFiles() throws {
        let config = MSAConfig.load()
        let fm = FileManager.default
        
        guard fm.fileExists(atPath: config.kernelPath) else {
            throw NSError(domain: "MSA", code: 1, userInfo: [NSLocalizedDescriptionKey: "Kernel manquant à : \(config.kernelPath)"])
        }
        
        let kernelAttrs = try fm.attributesOfItem(atPath: config.kernelPath)
        let kernelSize = (kernelAttrs[.size] as? UInt64) ?? 0
        if kernelSize < 1000000 {
            throw NSError(domain: "MSA", code: 2, userInfo: [NSLocalizedDescriptionKey: "Le fichier kernel est incomplet (\(kernelSize) octets)."])
        }
    }
    
    public func createConfiguration() throws -> VZVirtualMachineConfiguration {
        try validateFiles()
        let vzConfig = VZVirtualMachineConfiguration()
        let config = MSAConfig.load()
        
        // 1. CPU & Memory
        let maxCpu = ProcessInfo.processInfo.activeProcessorCount
        vzConfig.cpuCount = max(2, min(config.cpuCount, maxCpu))
        let memoryBytes = config.memorySizeMB * 1024 * 1024
        vzConfig.memorySize = max(VZVirtualMachineConfiguration.minimumAllowedMemorySize,
                                  min(memoryBytes, VZVirtualMachineConfiguration.maximumAllowedMemorySize))
        
        // 2. Linux Bootloader
        let bootLoader = VZLinuxBootLoader(kernelURL: URL(fileURLWithPath: config.kernelPath))
        bootLoader.commandLine = "console=hvc0 quiet loglevel=3 androidboot.hardware=virtio"
        vzConfig.bootLoader = bootLoader
        
        // 3. Serial Console
        let serial = VZVirtioConsoleDeviceSerialPortConfiguration()
        let stdioPipe = Pipe()
        let serialPortAttachment = VZFileHandleSerialPortAttachment(
            fileHandleForReading: FileHandle.standardInput,
            fileHandleForWriting: stdioPipe.fileHandleForWriting
        )
        serial.attachment = serialPortAttachment
        vzConfig.serialPorts = [serial]
        
        // 4. Entropy
        vzConfig.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]
        
        // 5. Network (Virtio NAT)
        let networkDevice = VZVirtioNetworkDeviceConfiguration()
        networkDevice.attachment = VZNATNetworkDeviceAttachment()
        vzConfig.networkDevices = [networkDevice]
        
        // 6. Sockets (Virtio Vsock)
        let socketDevice = VZVirtioSocketDeviceConfiguration()
        vzConfig.socketDevices = [socketDevice]
        
        try vzConfig.validate()
        return vzConfig
    }
    
    public func start() async throws {
        if case .running = state { return }
        state = .starting
        
        let vzConfig = try createConfiguration()
        let vm = VZVirtualMachine(configuration: vzConfig)
        vm.delegate = self
        self.virtualMachine = vm
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            vm.start { result in
                switch result {
                case .success:
                    self.state = .running
                    continuation.resume()
                case .failure(let error):
                    self.state = .error(error.localizedDescription)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func stop() async throws {
        guard let vm = virtualMachine, case .running = state else { return }
        state = .pausing
        try await vm.stop()
        state = .stopped
    }
    
    public func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        state = .stopped
    }
    
    public func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) {
        state = .error(error.localizedDescription)
    }
}
