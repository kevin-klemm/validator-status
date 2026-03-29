# Validator Status

A macOS desktop widget that monitors an Ethereum validator via the [beaconcha.in](https://beaconcha.in) API. Glance at your validator's health, balance, and status right from your desktop — and get notified when something changes.

[![Build](https://github.com/kevin-klemm-simplisafe/validator-status/actions/workflows/build.yml/badge.svg)](https://github.com/YOUR_USERNAME/validator-status/actions/workflows/build.yml)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black?logo=apple&logoColor=white)](https://developer.apple.com/macos/)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white)](https://swift.org)

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

This generates the Xcode project from `project.yml`. Then open `ValidatorStatus.xcodeproj` in Xcode and:

1. Select your signing team for both the **ValidatorStatus** and **ValidatorStatusWidget** targets
2. Ensure the **App Groups** capability is enabled with the group `group.com.validatorstatus.shared`
3. Build & Run the **ValidatorStatus** scheme
4. Right-click your desktop → **Edit Widgets** → add **Validator Status**

### Configure the widget

Long-press the widget and choose **Edit Widget** to set:

- **Validator Index** — your validator's numeric index
- **API Key** — your beaconcha.in API key

## How it works

The widget extension calls the beaconcha.in v2 API on each timeline refresh (hourly). The response is parsed into a `ValidatorStatus` struct that captures health, balance, and slashing info. `ValidatorStateStore` keeps the previous state in shared `UserDefaults` so the provider can detect transitions and fire a local notification via `NotificationManager` when the validator goes online, offline, or gets slashed.

## License

MIT
