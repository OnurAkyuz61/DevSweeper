import AppKit
import SwiftUI

/*
 MARK: - Erişim notları

 DevSweeper, Xcode DerivedData / Archives / DeviceSupport ve
 CoreSimulator dizinlerine okuma-yazma yapar.

 • App Sandbox projede kapalıdır (ENABLE_APP_SANDBOX = NO).
 • Yine de erişim engellenirse:
   Sistem Ayarları → Gizlilik ve Güvenlik → Tam Disk Erişimi
   → DevSweeper'ı ekleyin / açın.
 • Sistem genelindeki simülatör runtime'ları
   (/Library/Developer/CoreSimulator/Profiles/Runtimes)
   için yönetici yetkisi gerekebilir.
 */

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dock'ta görünsün ve normal uygulama gibi davransın.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@main
struct DevSweeperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 1000, height: 640)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
