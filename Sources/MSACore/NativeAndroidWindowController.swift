import AppKit
import Virtualization

public class NativeAndroidWindowController: NSWindowController {
    public static let shared = NativeAndroidWindowController()
    
    private var vzView: VZVirtualMachineView?
    
    public init() {
        let window = NSWindow(
            contentRect: NSRect(x: 120, y: 120, width: 1280, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Android 16 • Bare Metal"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = .black
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 640, height: 400)
        
        super.init(window: window)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        guard let window = self.window else { return }
        
        let virtualView = VZVirtualMachineView(frame: window.contentView?.bounds ?? NSRect(x: 0, y: 0, width: 1280, height: 800))
        virtualView.autoresizingMask = [.width, .height]
        virtualView.capturesSystemKeys = true
        
        if let vm = VMManager.shared.virtualMachine {
            virtualView.virtualMachine = vm
        }
        
        self.vzView = virtualView
        window.contentView = virtualView
    }
    
    public func attachAndShow(vm: VZVirtualMachine, title: String = "Android 16 • Bare Metal") {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let window = self.window else { return }
            window.title = title
            if self.vzView == nil {
                self.setupView()
            }
            self.vzView?.virtualMachine = vm
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
