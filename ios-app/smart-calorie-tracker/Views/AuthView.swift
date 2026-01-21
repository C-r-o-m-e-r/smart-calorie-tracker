import SwiftUI

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoginMode = true // Toggle between Login and Sign Up
    @State private var message = ""
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    
    var body: some View {
        if isLoggedIn {
            Text("Welcome! You are logged in.")
                .font(.largeTitle)
                .onAppear {
                }
        } else {
            VStack(spacing: 20) {
                Text(isLoginMode ? "Login" : "Sign Up")
                    .font(.largeTitle)
                    .bold()
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: handleAction) {
                    Text(isLoginMode ? "Login" : "Create Account")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: { isLoginMode.toggle() }) {
                    Text(isLoginMode ? "Don't have an account? Sign Up" : "Have an account? Login")
                        .foregroundColor(.blue)
                }
                
                if !message.isEmpty {
                    Text(message)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    func handleAction() {
        if isLoginMode {
            login()
        } else {
            register()
        }
    }
    
    func login() {
        NetworkService.shared.login(email: email, password: password) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.message = "Success!"
                    self.isLoggedIn = true
                case .failure:
                    self.message = "Login failed. Check credentials."
                }
            }
        }
    }
    
    func register() {
        NetworkService.shared.register(email: email, password: password, name: "User") { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.message = "Account created! Now logging in..."
                    self.login() // Auto login after signup
                case .failure:
                    self.message = "Registration failed."
                }
            }
        }
    }
}
