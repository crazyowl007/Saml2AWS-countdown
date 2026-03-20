import Foundation

struct SAMLCredentials {
    let expiresAt: Date

    var remainingTime: TimeInterval {
        expiresAt.timeIntervalSinceNow
    }

    var isExpired: Bool {
        remainingTime <= 0
    }

    var sessionState: SessionState {
        SessionState.from(remainingSeconds: remainingTime)
    }

    var formattedRemainingTime: String {
        let remaining = remainingTime
        if remaining <= 0 {
            return "Expired"
        }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            let seconds = Int(remaining) % 60
            if minutes > 0 {
                return "\(minutes)m \(seconds)s"
            }
            return "\(seconds)s"
        }
    }

    var formattedExpiresAt: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: expiresAt)
    }
}
