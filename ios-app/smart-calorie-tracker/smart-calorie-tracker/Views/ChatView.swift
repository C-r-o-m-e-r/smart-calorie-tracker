import SwiftUI

struct ChatView: View {
    @State private var text: String = ""

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("AI Assistant")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        Text("Hello! Take a photo of your food, and I will analyze it.")
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .padding()
                }
                
                HStack {
                    TextField("Ask something...", text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
                .padding()
            }
            .navigationTitle("AI Chat")
        }
    }
}

#Preview {
    ChatView()
}
