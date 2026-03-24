# SAML2AWS Countdown

macOS menu bar app showing countdown to AWS SAML session expiry.

## Build & Run

```bash
swift build        # build only
./run.sh           # build, create .app bundle, and open
```

- Uses **Swift Package Manager** (Package.swift), NOT Xcode
- Xcode not installed on this machine, only Command Line Tools
- No external dependencies

## Project Structure

```
SAML2AWSCountdown/
├── SAML2AWSCountdownApp.swift   # @main entry, MenuBarExtra (.window style)
├── Models/
│   ├── SessionState.swift       # Enum: active/expiringSoon/critical/expired/unknown
│   └── SAMLCredentials.swift    # Expiration date model with computed properties
├── ViewModels/
│   └── CountdownViewModel.swift # Timer, file watcher, refresh state
├── Views/
│   └── MenuContentView.swift    # Dropdown panel UI
└── Services/
    ├── CredentialsParser.swift       # Parses ~/.aws/credentials [saml] section
    ├── CredentialsFileWatcher.swift  # DispatchSource + polling file monitor
    ├── NotificationManager.swift     # UNUserNotificationCenter notifications
    └── SAML2AWSLoginService.swift    # Runs saml2aws login via forkpty (PTY)
```

## Key Technical Details

- **macOS 13+** required (MenuBarExtra API)
- **LSUIElement=YES** — no Dock icon, menu bar only
- **App Sandbox disabled** — needs access to `~/.aws/credentials`
- Reads `x_security_token_expires` from `[saml]` section in `~/.aws/credentials`
- 1-second timer updates countdown display
- File watcher auto-detects credential changes (DispatchSource + 60s polling fallback)
- Notifications at 30m, 15m, 5m, 1m before expiry and at expiry

## Refresh Button (saml2aws login)

- Runs `saml2aws login --skip-prompt --force` via `forkpty` pseudo-terminal
- **PTY is required** — saml2aws uses Go's survey library which checks `isatty()`; plain Pipe won't work
- Password auto-read from macOS Keychain (via `--skip-prompt`)
- MFA: uses arrow-key interactive selector, NOT numbered input. Default first option is PUSH MFA. We send Enter (CR `0x0d`) to confirm
- 120-second timeout for MFA push approval
- After success, CredentialsFileWatcher auto-detects the updated credentials

## saml2aws Config

- Config at `~/.saml2aws`, default account uses Okta provider
- Password must be stored in keychain first (run `saml2aws login` manually once)
