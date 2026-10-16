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

@main
struct DevSweeperApp: App {
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
