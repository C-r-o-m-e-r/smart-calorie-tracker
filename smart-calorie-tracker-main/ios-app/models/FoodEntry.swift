import SwiftData

@Model
final class FoodEntry {
    var name: String
    var calories: Int
    var date: Date

    init(name: String, calories: Int, date: Date = .now) {
        self.name = name
        self.calories = calories
        self.date = date
    }
}
