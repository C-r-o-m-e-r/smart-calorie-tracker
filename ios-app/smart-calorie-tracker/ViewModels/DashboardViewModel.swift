import Foundation
import SwiftData

@Observable
final class DashboardViewModel {

    var todayEntries: [FoodEntry] = []
    var totalCalories: Int = 0

    func loadTodayEntries(from entries: [FoodEntry]) {
        let calendar = Calendar.current
        let today = Date()

        todayEntries = entries.filter {
            calendar.isDate($0.date, inSameDayAs: today)
        }

        totalCalories = todayEntries.reduce(0) { $0 + $1.calories }
    }
}
