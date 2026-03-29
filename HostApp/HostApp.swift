import SwiftUI

/// Minimal host app — required by WidgetKit but invisible to the user.
/// LSUIElement = YES in Info.plist hides the dock icon and menu bar.
@main
struct HostApp: App {
    init() {
        NotificationManager.requestPermission()
    }

    var body: some Scene {
        Settings {
            Text("Validator Status")
                .onOpenURL { url in
                    NSWorkspace.shared.open(url)
                }
        }
    }
}
