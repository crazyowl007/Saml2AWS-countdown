# SAML2AWS Countdown

A macOS menu bar app that shows a countdown timer to your AWS SAML session expiry.

<!-- ![Screenshot](docs/screenshot.png) -->

## Features

- Displays remaining session time directly in the menu bar
- Color-coded status:
  - Green: > 30 minutes remaining
  - Yellow: 5-30 minutes remaining
  - Red: < 5 minutes remaining
  - Gray: session expired or no credentials found
- Desktop notifications at 30m, 15m, 5m, and 1m before expiry, and at expiry
- Automatically watches `~/.aws/credentials` for changes
- Lightweight, no Dock icon (menu bar only)

## Requirements

- macOS 13.0 (Ventura) or later
- [saml2aws](https://github.com/Versent/saml2aws) configured with a `[saml]` profile in `~/.aws/credentials`

## Installation

### Download DMG

Download the latest `.dmg` from the [Releases](../../releases) page, open it, and drag the app to your Applications folder.

> **Note:** Since the app is ad-hoc signed (no Apple Developer ID), macOS will block it on first launch. To open it:
> 1. Right-click the app and select **Open**, or
> 2. Go to **System Settings > Privacy & Security** and click **Open Anyway**

### Build from Source

```bash
git clone https://github.com/crazyowl007/Saml2AWS-countdown.git
cd saml2aws-countdown

# Run directly (debug build)
./run.sh

# Or install to /Applications (release build)
./install.sh
```

### Build a DMG

```bash
./scripts/build-release.sh 1.0.0
# Output: dist/SAML2AWSCountdown-1.0.0.dmg
```

## How It Works

The app reads the `x_security_token_expires` field from the `[saml]` section of `~/.aws/credentials` and displays a countdown in the menu bar. It monitors the file for changes using both file system events and periodic polling (every 30 seconds).

## App Icon

To build with a custom icon:

1. Place a 1024x1024 PNG at `Resources/AppIcon.png`
2. Run `./scripts/generate-icon.sh`
3. Rebuild the app

## License

[MIT](LICENSE)
