import SwiftUI

@main
struct ChargeDurationApp: App {
    @StateObject private var store = MeasurementStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
