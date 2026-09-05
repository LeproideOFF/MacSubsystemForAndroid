import Foundation

public class AppWrapperGenerator {
    public static let shared = AppWrapperGenerator()
    
    private let appsDirectory: URL
    
    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.appsDirectory = home.appendingPathComponent("Applications/Android Apps", isDirectory: true)
        try? FileManager.default.createDirectory(at: appsDirectory, withIntermediateDirectories: true)
    }
    
    public func createWrapper(packageName: String, appName: String) throws -> URL {
        let bundleURL = appsDirectory.appendingPathComponent("\(appName).app")
        let contentsURL = bundleURL.appendingPathComponent("Contents")
        let macosURL = contentsURL.appendingPathComponent("MacOS")
        let resourcesURL = contentsURL.appendingPathComponent("Resources")
        
        try FileManager.default.createDirectory(at: macosURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: resourcesURL, withIntermediateDirectories: true)
        
        // Info.plist
        let infoPlist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleExecutable</key>
            <string>launcher</string>
            <key>CFBundleIdentifier</key>
            <string>com.msa.android.\(packageName)</string>
            <key>CFBundleName</key>
            <string>\(appName)</string>
            <key>CFBundlePackageType</key>
            <string>APPL</string>
            <key>CFBundleShortVersionString</key>
            <string>1.0</string>
            <key>LSUIElement</key>
            <false/>
        </dict>
        </plist>
        """
        try infoPlist.write(to: contentsURL.appendingPathComponent("Info.plist"), atomically: true, encoding: .utf8)
        
        // Launcher executable script
        let launcherScript = """
        #!/bin/bash
        # Launcher for \(appName) (\(packageName)) via MSA
        
        # Start daemon if not running
        pgrep -f "msa-daemon" > /dev/null || open -g -a "MSADaemon"
        
        # Launch app inside Android subsystem
        /opt/homebrew/bin/adb shell monkey -p "\(packageName)" -c android.intent.category.LAUNCHER 1
        
        # Stream window seamlessly using scrcpy/display bridge
        if command -v scrcpy &> /dev/null; then
            scrcpy --window-title "\(appName)" --always-on-top=false --stay-awake &
        fi
        """
        let launcherURL = macosURL.appendingPathComponent("launcher")
        try launcherScript.write(to: launcherURL, atomically: true, encoding: .utf8)
        
        // Make executable (chmod +x)
        var attributes = try FileManager.default.attributesOfItem(atPath: launcherURL.path)
        attributes[.posixPermissions] = 0o755
        try FileManager.default.setAttributes(attributes, ofItemAtPath: launcherURL.path)
        
        return bundleURL
    }
}
