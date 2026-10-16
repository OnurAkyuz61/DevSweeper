import Foundation
import SwiftUI

/// Sol menüde gösterilen ana kategoriler.
enum SweepCategory: String, CaseIterable, Identifiable, Hashable {
    case cache
    case simulators

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cache: return String(localized: "Cache")
        case .simulators: return String(localized: "Simulators")
        }
    }

    var subtitle: String {
        switch self {
        case .cache: return String(localized: "Xcode caches")
        case .simulators: return String(localized: "Runtimes & devices")
        }
    }

    var systemImage: String {
        switch self {
        case .cache: return "internaldrive"
        case .simulators: return "iphone"
        }
    }
}
