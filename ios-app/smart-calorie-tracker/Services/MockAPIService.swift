import Foundation

struct FoodSuggestion: Identifiable {
    let id = UUID()
    let name: String
    let calories: Int
}

class MockAPIService {
    // База данных популярных продуктов
    private let database: [FoodSuggestion] = [
        FoodSuggestion(name: "Яблоко", calories: 52),
        FoodSuggestion(name: "Банан", calories: 89),
        FoodSuggestion(name: "Куриная грудка (100г)", calories: 165),
        FoodSuggestion(name: "Кофе с молоком", calories: 45),
        FoodSuggestion(name: "Яйцо вареное", calories: 155),
        FoodSuggestion(name: "Овсянка на воде", calories: 68),
        FoodSuggestion(name: "Пицца Маргарита", calories: 250),
        FoodSuggestion(name: "Гречка", calories: 132)
    ]
    
    // Имитация поиска
    func searchFood(query: String) -> [FoodSuggestion] {
        guard !query.isEmpty else { return [] }
        return database.filter { $0.name.lowercased().contains(query.lowercased()) }
    }
}