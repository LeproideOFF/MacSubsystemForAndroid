import Foundation
import MSACore

print("🟢 Starting MSA Daemon (Mac Subsystem for Android)...")

let vm = VMManager.shared

Task {
    do {
        try await vm.start()
        print("✅ MSA Daemon is active.")
    } catch {
        print("ℹ️ Note: VM boot configuration requires AOSP ARM64 kernel & system images in ~/.msa/images.")
        print("💡 Details: \(error.localizedDescription)")
    }
}

// Keep daemon running in background
dispatchMain()
