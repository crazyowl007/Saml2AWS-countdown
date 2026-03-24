import SwiftUI
import ServiceManagement

struct MenuContentView: View {
    @ObservedObject var viewModel: CountdownViewModel
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status header
            HStack {
                Image(systemName: viewModel.sessionState.sfSymbol)
                    .foregroundColor(viewModel.sessionState.color)
                    .font(.title2)
                Text(viewModel.sessionState.label)
                    .font(.headline)
                    .foregroundColor(viewModel.sessionState.color)
                Spacer()
            }

            Divider()

            if let creds = viewModel.credentials {
                // Remaining time
                HStack {
                    Text("Remaining:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(creds.formattedRemainingTime)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundColor(viewModel.sessionState.color)
                }

                // Expiry time
                HStack {
                    Text("Expires at:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(creds.formattedExpiresAt)
                        .font(.system(.body, design: .monospaced))
                }
            } else {
                Text("No SAML credentials found")
                    .foregroundColor(.secondary)
                Text("Run `saml2aws login` to authenticate")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Refresh button
            refreshSection

            Divider()

            // Settings & actions
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                }

            HStack {
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding()
        .frame(width: 280)
    }

    @ViewBuilder
    private var refreshSection: some View {
        switch viewModel.refreshState {
        case .idle:
            Button(action: { viewModel.refreshCredentials() }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh Session")
                }
                .frame(maxWidth: .infinity)
            }
            .controlSize(.large)

        case .refreshing(let status):
            HStack {
                ProgressView()
                    .controlSize(.small)
                Text(status)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Cancel") { viewModel.cancelRefresh() }
                    .controlSize(.small)
            }

        case .success:
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Session refreshed!")
                    .font(.caption)
            }

        case .failed(let error):
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("Refresh failed")
                        .font(.caption)
                }
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
    }
}
