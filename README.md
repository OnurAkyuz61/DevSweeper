# DevSweeper

macOS uygulaması — Xcode önbelleklerini ve CoreSimulator cihaz/runtime’larını tarayıp boyutlarını gösterir; güvenli veya kalıcı temizleme imkânı sunar.

## Özellikler

- **Önbellek (Cache)**
  - Derived Data (`~/Library/Developer/Xcode/DerivedData`)
  - Archives (`~/Library/Developer/Xcode/Archives`)
  - iOS Device Support (`~/Library/Developer/Xcode/iOS DeviceSupport`)
- **Simülatörler**
  - Runtime’lar (`/Library/Developer/CoreSimulator/Profiles/Runtimes`)
  - Cihazlar (`~/Library/Developer/CoreSimulator/Devices`) — UUID yerine okunabilir isim (`iPhone 16 — iOS 18.0`)
- NavigationSplitView + Table arayüzü
- Tekil / seçili / tümünü temizleme
- **Güvenli silme** (Çöp Kutusu) veya kalıcı silme
- Asenkron tarama ve silme (UI donmaz)
- Hata alert’leri (erişim reddi, kısmi silme vb.)

## Gereksinimler

- macOS 14.0+
- Xcode 15+ (geliştirme için)

## Kurulum

1. Repoyu klonlayın
2. `DevSweeper.xcodeproj` dosyasını Xcode ile açın
3. Scheme: **DevSweeper**, destination: **My Mac**
4. Run (`⌘R`)

## Erişim izinleri

Uygulama `~/Library/Developer` ve `/Library/Developer` altındaki Xcode / CoreSimulator dizinlerine erişir.

- **App Sandbox kapalıdır** (`ENABLE_APP_SANDBOX = NO`) — bu yollara erişim için gerekli
- Hâlâ engellenirse: **Sistem Ayarları → Gizlilik ve Güvenlik → Tam Disk Erişimi** üzerinden DevSweeper’a izin verin
- Sistem genelindeki runtime’ları silmek yönetici yetkisi gerektirebilir

## Mimari

SwiftUI + MVVM

```
DevSweeper/
├── DevSweeperApp.swift
├── ContentView.swift
├── Models/          # SweepCategory, SweepItem, SweepError
├── Services/        # SweepService, DiskSizeCalculator
├── ViewModels/      # SweepViewModel
└── Views/           # Sidebar, Table, Footer
```

## Kısayollar

| Kısayol | Eylem |
|--------|--------|
| `⌘R` | Listeyi yenile |
| `Delete` | Seçilenleri temizle |
| `⌘⇧⌫` | Tümünü temizle |

## Güvenlik notu

Silme işlemi geri alınamayabilir. Varsayılan mod **Çöp Kutusu**’na taşımadır; kalıcı silme için alttaki “Güvenli silme” seçeneğini kapatın. Xcode’u kullanırken Derived Data silmek sonraki build’i yavaşlatabilir.

## Lisans

Henüz belirtilmedi.
