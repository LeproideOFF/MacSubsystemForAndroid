import Foundation
@preconcurrency import Virtualization

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
            throw NSError(domain: "MSA", code: 1, userInfo: [NSLocalizedDescriptionKey: "Kernel Google Android 16 manquant à : \(config.kernelPath)"])
        }
        
        guard fm.fileExists(atPath: config.systemImagePath) else {
            throw NSError(domain: "MSA", code: 2, userInfo: [NSLocalizedDescriptionKey: "Image système Android 16 manquante à : \(config.systemImagePath)"])
        }
    }
    
    public func createConfiguration() throws -> VZVirtualMachineConfiguration {
        try validateFiles()
        let vzConfig = VZVirtualMachineConfiguration()
        let config = MSAConfig.load()
        
        // 1. CPU & Memory
        let maxCpu = ProcessInfo.processInfo.activeProcessorCount
        vzConfig.cpuCount = max(4, min(config.cpuCount, maxCpu))
        let memoryBytes = config.memorySizeMB * 1024 * 1024
        vzConfig.memorySize = max(VZVirtualMachineConfiguration.minimumAllowedMemorySize,
                                  min(memoryBytes, VZVirtualMachineConfiguration.maximumAllowedMemorySize))
        
        // 2. Linux Android 16 Bootloader (Official ranchu kernel + ramdisk)
        let bootLoader = VZLinuxBootLoader(kernelURL: URL(fileURLWithPath: config.kernelPath))
        let fm = FileManager.default
        if fm.fileExists(atPath: config.initrdPath) {
            bootLoader.initialRamdiskURL = URL(fileURLWithPath: config.initrdPath)
        }
        
        bootLoader.commandLine = "console=hvc0 console=tty0 earlycon=uart8250,mmio32,0x09000000 root=/dev/vda rw androidboot.hardware=ranchu androidboot.selinux=permissive androidboot.freeform_window_management=1 init=/init"
        vzConfig.bootLoader = bootLoader
        
        // 3. Serial Console
        let serial = VZVirtioConsoleDeviceSerialPortConfiguration()
        let serialPortAttachment = VZFileHandleSerialPortAttachment(
            fileHandleForReading: FileHandle.nullDevice,
            fileHandleForWriting: FileHandle.standardError
        )
        serial.attachment = serialPortAttachment
        vzConfig.serialPorts = [serial]
        
        // 4. Block Devices (Vraie partition Google AOSP 3.5 Go + Userdata 32 Go)
        var storageDevices: [VZStorageDeviceConfiguration] = []
        
        if fm.fileExists(atPath: config.systemImagePath) {
            let systemAttachment = try VZDiskImageStorageDeviceAttachment(
                url: URL(fileURLWithPath: config.systemImagePath),
                readOnly: false
            )
            let systemBlock = VZVirtioBlockDeviceConfiguration(attachment: systemAttachment)
            storageDevices.append(systemBlock)
        }
        
        if fm.fileExists(atPath: config.diskImagePath) {
            let dataAttachment = try VZDiskImageStorageDeviceAttachment(
                url: URL(fileURLWithPath: config.diskImagePath),
                readOnly: false
            )
            let dataBlock = VZVirtioBlockDeviceConfiguration(attachment: dataAttachment)
            storageDevices.append(dataBlock)
        }
        vzConfig.storageDevices = storageDevices
        
        // 5. Entropy
        vzConfig.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]
        
        // 6. Network (Virtio NAT)
        let networkDevice = VZVirtioNetworkDeviceConfiguration()
        networkDevice.attachment = VZNATNetworkDeviceAttachment()
        vzConfig.networkDevices = [networkDevice]
        
        // 7. Sockets (Virtio Vsock)
        let socketDevice = VZVirtioSocketDeviceConfiguration()
        vzConfig.socketDevices = [socketDevice]
        
        // 8. Bare Metal Graphics (Virtio-GPU Metal Scanout Zéro-Vidéo)
        let graphicsDevice = VZVirtioGraphicsDeviceConfiguration()
        let scanout = VZVirtioGraphicsScanoutConfiguration(widthInPixels: 1920, heightInPixels: 1200)
        graphicsDevice.scanouts = [scanout]
        vzConfig.graphicsDevices = [graphicsDevice]
        
        // 9. Bare Metal Pointer & Keyboard (Entrées directes sans ADB)
        let pointingDevice = VZUSBScreenCoordinatePointingDeviceConfiguration()
        vzConfig.pointingDevices = [pointingDevice]
        
        let keyboardDevice = VZUSBKeyboardConfiguration()
        vzConfig.keyboards = [keyboardDevice]
        
        try vzConfig.validate()
        return vzConfig
    }
    
    public func start() async throws {
        if case .running = state { return }
        state = .starting
        
        let vzConfig = try createConfiguration()
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.main.async {
                let vm = VZVirtualMachine(configuration: vzConfig, queue: .main)
                vm.delegate = self
                self.virtualMachine = vm
                
                vm.start { result in
                    switch result {
                    case .success:
                        self.state = .running
                        NativeAndroidWindowController.shared.attachAndShow(vm: vm, title: "Android 16 • Bare Metal (Metal Graphics)")
                        continuation.resume()
                    case .failure(let error):
                        print("❌ [VMManager] VZVirtualMachine.start FAILED: \(error)")
                        self.state = .error(error.localizedDescription)
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    public func stop() async throws {
        guard let vm = virtualMachine, case .running = state else { return }
        state = .pausing
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.main.async {
                vm.stop { error in
                    if let error = error {
                        self.state = .error(error.localizedDescription)
                        continuation.resume(throwing: error)
                    } else {
                        self.state = .stopped
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    public func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        DispatchQueue.main.async {
            self.state = .stopped
        }
    }
    
    public func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) {
        DispatchQueue.main.async {
            self.state = .error(error.localizedDescription)
        }
    }
}
