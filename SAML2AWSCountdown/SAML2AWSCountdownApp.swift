import SwiftUI

@main
struct SAML2AWSCountdownApp: App {
    @StateObject private var viewModel = CountdownViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(viewModel: viewModel)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.sessionState.sfSymbol)
                Text(viewModel.menuBarText)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
