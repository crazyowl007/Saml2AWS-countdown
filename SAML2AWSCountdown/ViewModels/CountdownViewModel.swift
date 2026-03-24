import Foundation
import Combine

final class CountdownViewModel: ObservableObject {
    @Published var credentials: SAMLCredentials?
    @Published var menuBarText: String = "SAML: --"
    @Published var sessionState: SessionState = .unknown
    @Published var refreshState: RefreshState = .idle

    private var timer: Timer?
    private var fileWatcher: CredentialsFileWatcher?
    private let notificationManager = NotificationManager.shared
    private let loginService = SAML2AWSLoginService()

    init() {
        loadCredentials()
        startFileWatcher()
        startTimer()
    }

    deinit {
        timer?.invalidate()
        fileWatcher = nil
    }

    func refresh() {
        loadCredentials()
    }

    func refreshCredentials() {
        guard refreshState == .idle else { return }

        loginService.login(
            onStateChange: { [weak self] state in
                self?.refreshState = state
            },
            completion: { [weak self] success in
                if success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.refreshState = .idle
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self?.refreshState = .idle
                    }
                }
            }
        )
    }

    func cancelRefresh() {
        loginService.cancel()
        refreshState = .idle
    }

    private func loadCredentials() {
        credentials = CredentialsParser.parse()
        if let creds = credentials {
            if !creds.isExpired {
                notificationManager.scheduleNotifications(for: creds)
            }
        } else {
            notificationManager.cancelAllNotifications()
        }
        updateDisplay()
    }

    private func startFileWatcher() {
        fileWatcher = CredentialsFileWatcher { [weak self] in
            self?.loadCredentials()
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateDisplay()
        }
    }

    private func updateDisplay() {
        guard let creds = credentials else {
            menuBarText = "SAML: --"
            sessionState = .unknown
            return
        }

        sessionState = creds.sessionState
        if creds.isExpired {
            menuBarText = "SAML: Expired"
        } else {
            menuBarText = "SAML: \(creds.formattedRemainingTime)"
        }
    }
}
