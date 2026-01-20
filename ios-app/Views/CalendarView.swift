import SwiftUI

struct CalendarView: View {
	@State private var selectedDate = Date()

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .leading, spacing: 16) {
					Text("Calendar")
						.font(.largeTitle.bold())

					DatePicker(
						"Select date",
						selection: $selectedDate,
						displayedComponents: [.date]
					)
					.datePickerStyle(.graphical)
					.tint(.blue)

					VStack(alignment: .leading, spacing: 8) {
						Text("Selected date")
							.font(.headline)

						Text(selectedDate.formatted(date: .long, time: .omitted))
							.font(.title3.weight(.semibold))
					}
					.padding()
					.frame(maxWidth: .infinity, alignment: .leading)
					.background(Color(.secondarySystemBackground))
					.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

					VStack(alignment: .leading, spacing: 8) {
						Text("Meals")
							.font(.headline)

						Text("No meals for this day yet.")
							.foregroundColor(.secondary)
					}
					.padding()
					.frame(maxWidth: .infinity, alignment: .leading)
					.background(Color(.secondarySystemBackground))
					.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
				}
				.padding()
			}
		}
	}
}

#Preview {
	CalendarView()
}
