import Foundation
import SwiftData

@Model
final class Meal: Identifiable {
    var id: UUID
    var name: String
    var calories: Int
    var protein: Double
    var fats: Double
    var carbs: Double
    var date: Date
    var imagePath: String? // Optional path if we save the photo locally

    init(name: String, calories: Int, protein: Double, fats: Double, carbs: Double, date: Date = Date(), imagePath: String? = nil) {
        self.id = UUID()
        self.name = name
        self.calories = calories
        self.protein = protein
        self.fats = fats
        self.carbs = carbs
        self.date = date
        self.imagePath = imagePath
    }
}
