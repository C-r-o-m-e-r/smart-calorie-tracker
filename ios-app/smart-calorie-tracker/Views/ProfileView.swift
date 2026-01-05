import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var context
    
    // Запрашиваем профиль из базы
    @Query private var profiles: [UserProfile]
    
    // Временные состояния для полей ввода
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var dailyGoal: String = ""
    
    // Текущий профиль (первый из списка)
    var userProfile: UserProfile? {
        profiles.first
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Параметры тела")) {
                    HStack {
                        Text("Вес (кг)")
                        Spacer()
                        TextField("0", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Рост (см)")
                        Spacer()
                        TextField("0", text: $height)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("Цели")) {
                    HStack {
                        Text("Дневная норма ккал")
                        Spacer()
                        TextField("2000", text: $dailyGoal)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Button("Сохранить изменения") {
                    saveProfile()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.blue)
            }
            .navigationTitle("Профиль")
            .onAppear {
                // При открытии заполняем поля данными из базы
                if let profile = userProfile {
                    weight = String(profile.weight)
                    height = String(profile.height)
                    dailyGoal = String(profile.dailyCalories)
                }
            }
        }
    }

    private func saveProfile() {
        let w = Double(weight) ?? 0.0
        let h = Double(height) ?? 0.0
        let g = Int(dailyGoal) ?? 2000
        
        if let profile = userProfile {
            // Обновляем существующий
            profile.weight = w
            profile.height = h
            profile.dailyCalories = g
        } else {
            // Создаем новый, если базы еще нет
            let newProfile = UserProfile(weight: w, height: h, dailyCalories: g)
            context.insert(newProfile)
        }
        
        try? context.save()
    }
}