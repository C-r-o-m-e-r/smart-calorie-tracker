import SwiftData

@Model
final class UserProfile {
    var weight: Double
    var height: Double
    var dailyCalories: Int

    init(weight: Double, height: Double, dailyCalories: Int) {
        self.weight = weight
        self.height = height
        self.dailyCalories = dailyCalories
    }
}
