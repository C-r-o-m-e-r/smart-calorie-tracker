import SwiftUI
import SwiftData

@main
struct SmartPlateApp: App {

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(for: [
            UserProfile.self,
            FoodEntry.self,
            ChatMessage.self
        ])
    }
}
