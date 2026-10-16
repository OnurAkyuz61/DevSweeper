# Changelog

Bu dosya [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) formatına uyar.
Sürümleme [Semantic Versioning](https://semver.org/) ile yapılır.

## [Unreleased]

### Added

- Genişletilebilir ağaç görünümü: grupların (Derived Data, Archives, Device Support, Runtimes, Devices) altındaki öğeler listelenir ve tek tek silinebilir
- Xcode’u etkileyen öğelerde turuncu uyarı üçgeni ve silme onayında uyarı metni (Device Support, Simulator Runtimes)
- Yerelleştirme: Türkçe / İngilizce (diğer diller İngilizceye düşer)

## [1.0.0] — 2026-10-16

### Added

- macOS SwiftUI uygulaması (MVVM)
- Önbellek taraması: Derived Data, Archives, iOS Device Support
- Simülatör taraması: CoreSimulator runtimes ve cihazlar
- Okunabilir simülatör isimleri (`device.plist` / runtime kimliği ayrıştırma)
- NavigationSplitView sidebar (Önbellek / Simülatörler)
- Table görünümü: ad, yol, boyut, Sil butonu
- Alt özet çubuğu ve “Tümünü Temizle”
- Çoklu seçim ve “Seçilenleri Temizle”
- Güvenli silme (Çöp Kutusu) / kalıcı silme seçeneği
- Asenkron silme ve otomatik liste yenileme
- Hata yönetimi ve onay dialog’ları
- App Sandbox kapalı; Tam Disk Erişimi notları
- `.gitignore` (Xcode / macOS)

[Unreleased]: https://github.com/onurakyuz/DevSweeper/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/onurakyuz/DevSweeper/releases/tag/v1.0.0
