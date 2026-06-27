import AppIntents

struct VitalsShortcuts: AppShortcutsProvider {
  static var shortcutTileColor: ShortcutTileColor = .red

  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: ExportHealthToHemWebIntent(),
      phrases: [
        "Export Health to \(.applicationName)",
        "Export \(.applicationName) health",
      ],
      shortTitle: "Export Health",
      systemImageName: "heart.text.square"
    )

    AppShortcut(
      intent: ExportPreviousDayHealthToHemWebIntent(),
      phrases: [
        "Export yesterday's Health to \(.applicationName)",
        "Export previous day health to \(.applicationName)",
      ],
      shortTitle: "Export Yesterday",
      systemImageName: "calendar.badge.clock"
    )
  }
}
