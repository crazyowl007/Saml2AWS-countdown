import SwiftUI

enum SessionState {
    case active
    case expiringSoon
    case critical
    case expired
    case unknown

    var color: Color {
        switch self {
        case .active: return .green
        case .expiringSoon: return .yellow
        case .critical: return .red
        case .expired: return .red
        case .unknown: return .gray
        }
    }

    var sfSymbol: String {
        switch self {
        case .active: return "lock.shield"
        case .expiringSoon: return "exclamationmark.shield"
        case .critical: return "exclamationmark.shield"
        case .expired: return "xmark.shield"
        case .unknown: return "questionmark.circle"
        }
    }

    var label: String {
        switch self {
        case .active: return "Active"
        case .expiringSoon: return "Expiring Soon"
        case .critical: return "Critical"
        case .expired: return "Expired"
        case .unknown: return "Unknown"
        }
    }

    static func from(remainingSeconds: TimeInterval) -> SessionState {
        if remainingSeconds <= 0 {
            return .expired
        } else if remainingSeconds <= 5 * 60 {
            return .critical
        } else if remainingSeconds <= 30 * 60 {
            return .expiringSoon
        } else {
            return .active
        }
    }
}
