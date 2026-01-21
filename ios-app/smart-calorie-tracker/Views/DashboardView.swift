import SwiftUI
import SwiftData

struct DashboardView: View {
    // Profile access to get the calorie goal
    @Query private var profiles: [UserProfile]
    // Access to all food entries
    @Query(sort: \FoodEntry.date, order: .reverse) private var allEntries: [FoodEntry]
    
    @Environment(\.modelContext) private var context

    @State private var showAddMeal = false
    
    init() {}
    
    // Calculate goal (from profile or 2000 by default)
    private var dailyGoal: Int {
        profiles.first?.dailyCalories ?? 2000
    }
    
    // Records for today only
    private var todayEntries: [FoodEntry] {
        allEntries.filter { Calendar.current.isDateInToday($0.date) }
    }
    
    // Total for today
    private var totalCalories: Int {
        todayEntries.reduce(0) { $0 + $1.calories }
    }
    
    // How much is left
    private var remainingCalories: Int {
        dailyGoal - totalCalories
    }

    private func deleteEntry(_ entry: FoodEntry) {
        context.delete(entry)
        // Changes will be saved automatically thanks to SwiftData
    }

    var body: some View {
        NavigationStack {
            ScrollView { // Using ScrollView for interface flexibility
                VStack(alignment: .leading, spacing: 24) {
                   
                    // Statistics block
                    VStack(spacing: 8) {
                        Text("Remaining")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                      
                        Text("\(remainingCalories)")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundColor(remainingCalories >= 0 ? .primary : .red)
                      
                        Text("of \(dailyGoal) kcal")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)).shadow(radius: 2))

                    // List header
                    Text("Today's Meals")
                        .font(.title2)
                        .bold()
                   
                    if todayEntries.isEmpty {
                        ContentUnavailableView("No entries", systemImage: "fork.knife", description: Text("Add your first meal today"))
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
                                Text("\(entry.calories) kcal")
                                    .fontWeight(.semibold)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteEntry(entry)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Tracker")
            .safeAreaInset(edge: .bottom) { // Button sticks to the bottom
                Button {
                    showAddMeal = true
                } label: {
                    Label("Add Meal", systemImage: "plus")
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
