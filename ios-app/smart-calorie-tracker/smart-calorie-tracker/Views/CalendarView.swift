import SwiftUI

struct CalendarView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "calendar")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .padding()
                
                Text("Calendar History")
                    .font(.title)
                    .bold()
                
                Text("Your meal history will appear here.")
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .navigationTitle("Calendar")
        }
    }
}

#Preview {
    CalendarView()
}
