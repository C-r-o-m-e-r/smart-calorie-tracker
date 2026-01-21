import Foundation
import SwiftData

@Model
final class UserProfile {
    var weight: Double
    var height: Double
    var dailyCalories: Int
    var activityLevel: String

    init(weight: Double, height: Double, dailyCalories: Int, activityLevel: String) {
        self.weight = weight
        self.height = height
        self.dailyCalories = dailyCalories
        self.activityLevel = activityLevel
    }
    
    // Вычисляем ИМТ: Вес / (Рост в метрах ^ 2)
    var bmi: Double {
        guard height > 0 else { return 0 }
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
    
    // Текст для отображения статуса
    var bmiStatus: String {
        switch bmi {
        case ..<18.5: return "Недостаточный вес"
        case 18.5..<25: return "Норма"
        case 25..<30: return "Избыточный вес"
        default: return "Ожирение"
        }
    }
}