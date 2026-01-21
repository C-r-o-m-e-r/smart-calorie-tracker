import SwiftUI
import SwiftData

@main
struct SmartCalorieTrackerApp: App {
    @StateObject private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            AuthGateView()
                .environmentObject(authVM)
        }
        .modelContainer(for: [
            UserProfile.self,
            FoodEntry.self,
            ChatMessage.self
        ])
    }
}
