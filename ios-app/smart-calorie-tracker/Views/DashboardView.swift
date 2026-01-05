import SwiftUI
import SwiftData

struct DashboardView: View {
    // Доступ к профилю для получения цели калорий
    @Query private var profiles: [UserProfile]
    // Доступ ко всем записям еды
    @Query(sort: \FoodEntry.date, order: .reverse) private var allEntries: [FoodEntry]
    
    @Environment(\.modelContext) private var context

    @State private var showAddMeal = false
    
    init() {}
    
    // Вычисляем цель (из профиля или 2000 по умолчанию)
    private var dailyGoal: Int {
        profiles.first?.dailyCalories ?? 2000
    }
    
    // Записи только за сегодня
    private var todayEntries: [FoodEntry] {
        allEntries.filter { Calendar.current.isDateInToday($0.date) }
    }
    
    // Сумма за сегодня
    private var totalCalories: Int {
        todayEntries.reduce(0) { $0 + $1.calories }
    }
    
    // Сколько осталось
    private var remainingCalories: Int {
        dailyGoal - totalCalories
    }

    private func deleteEntry(_ entry: FoodEntry) {
        context.delete(entry)
        // Изменения сохранятся автоматически благодаря SwiftData
    }

    var body: some View {
        NavigationStack {
            ScrollView { // Используем ScrollView для гибкости интерфейса
                VStack(alignment: .leading, spacing: 24) {
                   
                    // Блок со статистикой
                    VStack(spacing: 8) {
                        Text("Осталось")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                      
                        Text("\(remainingCalories)")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundColor(remainingCalories >= 0 ? .primary : .red)
                      
                        Text("из \(dailyGoal) ккал")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)).shadow(radius: 2))

                    // Заголовок списка
                    Text("Сегодняшние приемы пищи")
                        .font(.title2)
                        .bold()
                   
                    if todayEntries.isEmpty {
                        ContentUnavailableView("Нет записей", systemImage: "fork.knife", description: Text("Добавьте ваш первый прием пищи сегодня"))
                    } else {
                        ForEach(todayEntries) { entry in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(entry.name)
                                        .font(.headline)
                                    Text(entry.date.formatted(date: .omitted, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("\(entry.calories) ккал")
                                    .fontWeight(.semibold)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteEntry(entry)
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Трекер")
            .safeAreaInset(edge: .bottom) { // Кнопка прилипает к низу
                Button {
                    showAddMeal = true
                } label: {
                    Label("Добавить еду", systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .cornerRadius(15)
                .padding()
                .background(.ultraThinMaterial)
            }
            .sheet(isPresented: $showAddMeal) {
                AddMealView()
            }
        }
    }
}
