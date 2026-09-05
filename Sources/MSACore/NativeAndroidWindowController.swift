import AppKit
import Virtualization
import MSACore

public class NativeAndroidWindowController: NSWindowController {
    public static let shared = NativeAndroidWindowController()
    
    private var vzView: VZVirtualMachineView?
    
    public init() {
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1080, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Android 16 • Bare Metal (Metal Graphics)"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 480, height: 320)
        
        super.init(window: window)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        guard let window = self.window else { return }
        
        let containerView = NSView(frame: window.contentView?.bounds ?? .zero)
        containerView.autoresizingMask = [.width, .height]
        
        let virtualView = VZVirtualMachineView(frame: containerView.bounds)
        virtualView.autoresizingMask = [.width, .height]
        virtualView.capturesSystemKeys = true
        
        // Attacher l'instance de machine virtuelle Bare Metal
        if let vm = VMManager.shared.virtualMachine {
            virtualView.virtualMachine = vm
        }
        
        self.vzView = virtualView
        containerView.addSubview(virtualView)
        window.contentView = containerView
    }
    
    public func attachAndShow(vm: VZVirtualMachine, title: String = "Android 16 • Bare Metal") {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let window = self.window else { return }
            window.title = title
            self.vzView?.virtualMachine = vm
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
