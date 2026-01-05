import SwiftUI

struct CalendarView: View {
    var body: some View {
        VStack {
            Image(systemName: "calendar")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .padding()
            
            Text("Календар")
                .font(.title)
                .bold()
            
            Text("Тут буде історія твоїх прийомів їжі")
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    CalendarView()
}
