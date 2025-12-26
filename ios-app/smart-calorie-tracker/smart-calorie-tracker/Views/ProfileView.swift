import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("My Details")) {
                    HStack {
                        Text("Weight")
                        Spacer()
                        Text("75 kg").foregroundColor(.gray)
                    }
                    HStack {
                        Text("Height")
                        Spacer()
                        Text("180 cm").foregroundColor(.gray)
                    }
                    HStack {
                        Text("Age")
                        Spacer()
                        Text("25").foregroundColor(.gray)
                    }
                }
                
                Section {
                    Button("Log Out") {
                        // Logout action
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
}
