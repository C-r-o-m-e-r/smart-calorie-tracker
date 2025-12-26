import SwiftUI
import SwiftData

struct DashboardView: View {

    @State private var viewModel = DashboardViewModel()

    @Query(sort: \FoodEntry.date, order: .reverse)
    private var allEntries: [FoodEntry]

    @State private var showAddMeal = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {

                Text("Today")
                    .font(.largeTitle)
                    .bold()

                Text("Calories today: \(viewModel.totalCalories)")
                    .font(.title2)

                List {
                    ForEach(viewModel.todayEntries) { entry in
                        HStack {
                            Text(entry.name)
                            Spacer()
                            Text("\(entry.calories) kcal")
                        }
                    }
                }

                Button {
                    showAddMeal = true
                } label: {
                    Text("+ Add meal")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .onAppear {
                viewModel.loadTodayEntries(from: allEntries)
            }
            .sheet(isPresented: $showAddMeal) {
                AddMealView()
            }
        }
    }
}
