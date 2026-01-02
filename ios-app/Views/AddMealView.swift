import SwiftUI
import SwiftData

struct AddMealView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var caloriesText: String = ""
    
    // Подключаем наш сервис
    private let apiService = MockAPIService()
    @State private var suggestions: [FoodSuggestion] = []

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Название блюда")) {
                    TextField("Что вы съели?", text: $name)
                        .onChange(of: name) {
                            // Ищем подсказки при каждом изменении текста
                            suggestions = apiService.searchFood(query: name)
                        }
                    
                    // Выпадающий список подсказок
                    if !suggestions.isEmpty {
                        ForEach(suggestions) { suggestion in
                            Button {
                                self.name = suggestion.name
                                self.caloriesText = String(suggestion.calories)
                                self.suggestions = [] // Прячем подсказки после выбора
                            } label: {
                                HStack {
                                    Text(suggestion.name)
                                    Spacer()
                                    Text("\(suggestion.calories) ккал").foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Энергетическая ценность")) {
                    TextField("Калории", text: $caloriesText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Новая запись")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveMeal()
                    }
                    .disabled(name.isEmpty || caloriesText.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }

    private func saveMeal() {
        guard let calories = Int(caloriesText) else { return }
        let entry = FoodEntry(name: name, calories: calories, date: Date())
        context.insert(entry)
        dismiss()
    }
}