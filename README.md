# Validator Status

A macOS desktop widget that monitors an Ethereum validator via the [beaconcha.in](https://beaconcha.in) API. Glance at your validator's health, balance, and status right from your desktop — and get notified when something changes.

[![Build](https://github.com/kevin-klemm-simplisafe/validator-status/actions/workflows/build.yml/badge.svg)](https://github.com/kevin-klemm-simplisafe/validator-status/actions/workflows/build.yml)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black?logo=apple&logoColor=white)](https://developer.apple.com/macos/)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- **Small and medium widget sizes** — the small widget shows status at a glance; the medium widget adds current and effective balance
- **Tap to open** — tapping the widget opens your validator's charts page on beaconcha.in
- **State change notifications** — desktop notifications fire when your validator goes online/offline or gets slashed
- **Hourly refresh** — the widget fetches fresh data from the beaconcha.in v2 API every hour

## Setup

### Prerequisites

- macOS 14.0+
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (installed automatically by the setup script if missing)
- A [beaconcha.in API key](https://beaconcha.in/pricing)

### Build and install

```bash
./setup.sh
```

This generates the Xcode project from `project.yml`. Then open `validator-status.xcodeproj` in Xcode and:

1. Select your signing team for both the **validator-status** and **validator-status-widget** targets
2. Ensure the **App Groups** capability is enabled with the group `group.com.validatorstatus.shared`
3. Build & Run the **validator-status** scheme
4. Right-click your desktop → **Edit Widgets** → add **Validator Status**

### GitHub Actions artifacts

`build.yml` is CI only. It compiles, tests, and uploads `Validator-Status-unsigned` for debugging. That artifact is not meant for end users and Gatekeeper will block it after download.

`release.yml` is the distributable path. It builds the app, signs it with your Developer ID certificate, notarizes it with Apple, staples the result, and uploads `Validator-Status-macOS.zip`. If the workflow runs from a tag like `v1.0.0`, it also attaches that zip to a GitHub Release so users can just download and open it.

### One-time release setup

Required repository secrets for a distributable macOS artifact:

- `APPLE_CERTIFICATE_P12_BASE64` — base64-encoded Developer ID Application certificate export
- `APPLE_CERTIFICATE_PASSWORD` — password for that `.p12`
- `APPLE_SIGNING_IDENTITY` — the full `Developer ID Application: ...` identity name
- `APPLE_TEAM_ID` — your Apple Developer team ID
- `APPLE_ID` — the Apple ID used for notarization
- `APPLE_APP_SPECIFIC_PASSWORD` — app-specific password for that Apple ID

After those secrets are set once, shipping a new version is just:

1. Push a tag like `v1.0.0`, or run the `Release` workflow manually
2. Wait for `release.yml` to finish
3. Share the generated `Validator-Status-macOS.zip` asset from the GitHub Release

End users do not need to set any environment variables. They should download the notarized release artifact, not the unsigned CI artifact.

### Configure the widget

Long-press the widget and choose **Edit Widget** to set:

- **Validator Index** — your validator's numeric index
- **API Key** — your beaconcha.in API key

## How it works

The widget extension calls the beaconcha.in v2 API on each timeline refresh (hourly). The response is parsed into a `ValidatorStatus` struct that captures health, balance, and slashing info. `ValidatorStateStore` keeps the previous state in shared `UserDefaults` so the provider can detect transitions and fire a local notification via `NotificationManager` when the validator goes online, offline, or gets slashed.
