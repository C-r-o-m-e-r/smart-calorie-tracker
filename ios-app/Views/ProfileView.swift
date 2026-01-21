import SwiftUI
import SwiftData

private enum ActivityLevel: String, CaseIterable, Identifiable {
    case inactive = "Неактивный"
    case active = "Активный"

    var id: String { rawValue }

    var multiplier: Double {
        switch self {
        case .inactive: return 1.2
        case .active: return 1.55
        }
    }
}

struct ProfileView: View {
    @Environment(\.modelContext) private var context
    
    // Запрашиваем профиль из базы
    @Query private var profiles: [UserProfile]
    
    // Временные состояния для полей ввода
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var activityLevel: ActivityLevel = .inactive
    
    // Текущий профиль (первый из списка)
    var userProfile: UserProfile? {
        profiles.first
    }

    private var calculatedDailyCalories: Int {
        let w = Double(weight) ?? 0.0
        let h = Double(height) ?? 0.0

        guard w > 0, h > 0 else { return 0 }

        let base = 10 * w + 6.25 * h
        let total = base * activityLevel.multiplier
        return Int(total.rounded())
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

                Section(header: Text("Активность")) {
                    Picker("Образ жизни", selection: $activityLevel) {
                        ForEach(ActivityLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Цели")) {
                    HStack {
                        Text("Дневная норма ккал")
                        Spacer()
                        Text("\(calculatedDailyCalories)")
                            .foregroundColor(.secondary)
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
                    activityLevel = ActivityLevel(rawValue: profile.activityLevel) ?? .inactive
                }
            }
        }
    }

    private func saveProfile() {
        let w = Double(weight) ?? 0.0
        let h = Double(height) ?? 0.0
        let g = calculatedDailyCalories
        let activity = activityLevel.rawValue
        
        if let profile = userProfile {
            // Обновляем существующий
            profile.weight = w
            profile.height = h
            profile.dailyCalories = g
            profile.activityLevel = activity
        } else {
            // Создаем новый, если базы еще нет
            let newProfile = UserProfile(weight: w, height: h, dailyCalories: g, activityLevel: activity)
            context.insert(newProfile)
        }
        
        try? context.save()
    }
}