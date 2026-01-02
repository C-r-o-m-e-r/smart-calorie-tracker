import SwiftUI
import SwiftData

struct AddMealView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var caloriesText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Meal name", text: $name)

                TextField("Calories", text: $caloriesText)
                    .keyboardType(.numberPad)
            }
            .navigationTitle("Add meal")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMeal()
                    }
                }
            }
        }
    }

    private func saveMeal() {
        guard
            !name.isEmpty,
            let calories = Int(caloriesText)
        else { return }

        let entry = FoodEntry(
            name: name,
            calories: calories,
            date: Date()
        )

        context.insert(entry)
        try? context.save()

        dismiss()
    }
}
