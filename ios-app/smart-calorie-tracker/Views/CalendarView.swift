import SwiftUI
import SwiftData

struct CalendarView: View {
    // MARK: - PERSISTENCE
    @Environment(\.modelContext) private var context
    
    // Fetch all entries sorted by date
    @Query(sort: \FoodEntry.date, order: .reverse) private var allEntries: [FoodEntry]
    
    // MARK: - STATE
    @State private var selectedDate = Date()
    
    // MARK: - COMPUTED LOGIC
    private var filteredEntries: [FoodEntry] {
        let calendar = Calendar.current
        return allEntries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: selectedDate)
        }
    }
    
    private var dailyTotalCalories: Int {
        filteredEntries.reduce(0) { $0 + $1.calories }
    }
    
    // MARK: - HELPER FUNCTIONS
    private func deleteEntry(_ entry: FoodEntry) {
        context.delete(entry)
        try? context.save()
    }
    
    // MARK: - VIEW BODY
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 1. DATE PICKER CARD (Matches Statistics Block Style)
                    VStack(spacing: 8) {
                        DatePicker(
                            "Select Date",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .tint(.blue)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)).shadow(radius: 2))
                    
                    // 2. SUMMARY BLOCK (Matches "Remaining" Block Style)
                    VStack(spacing: 8) {
                        Text("Total Intake")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(dailyTotalCalories)")
                            .font(.system(size: 60, weight: .bold, design: .rounded)) // Matching Dashboard big font
                            .foregroundColor(.blue)
                        
                        Text("kcal on \(selectedDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)).shadow(radius: 2))
                    
                    // 3. MEALS LIST HEADER
                    Text("History Records")
                        .font(.title2)
                        .bold()
                    
                    // 4. MEALS LIST (Matches "Today's Meals" Style)
                    if filteredEntries.isEmpty {
                        ContentUnavailableView("No entries", systemImage: "calendar.badge.exclamationmark", description: Text("No meals recorded for this date"))
                    } else {
                        ForEach(filteredEntries) { entry in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(entry.name)
                                        .font(.headline) // Matches Dashboard
                                    
                                    Text(entry.date.formatted(date: .omitted, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("\(entry.calories) kcal")
                                    .fontWeight(.semibold) // Matches Dashboard
                                    .font(.system(.body, design: .rounded))
                            }
                            .padding()
                            // EXACT MATCH: Using secondarySystemBackground instead of white cards
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
            .navigationTitle("History") // Standard title matches "Tracker"
        }
    }
}

// MARK: - PREVIEW
#Preview {
    CalendarView()
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
