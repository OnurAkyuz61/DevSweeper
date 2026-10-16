import Foundation
import SwiftUI

/// Sol menüde gösterilen ana kategoriler.
enum SweepCategory: String, CaseIterable, Identifiable, Hashable {
    case cache
    case simulators

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cache: return "Önbellek"
        case .simulators: return "Simülatörler"
        }
    }

    var subtitle: String {
        switch self {
        case .cache: return "Cache"
        case .simulators: return "Simulators"
        }
    }

    var systemImage: String {
        switch self {
        case .cache: return "internaldrive"
        case .simulators: return "iphone"
        }
    }
}
