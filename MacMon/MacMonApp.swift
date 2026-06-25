import SwiftUI

@main
struct MacMonApp: App {
    @StateObject private var store = MetricsStore()

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environmentObject(store)
        } label: {
            MenuBarLabel(store: store)
        }
        .menuBarExtraStyle(.window)   // окно в стиле liquid glass, а не системное меню
    }
}
