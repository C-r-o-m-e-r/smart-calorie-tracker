import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isRegisterMode = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Smart Calorie Tracker")
                    .font(.largeTitle)
                    .bold()

                Picker("Режим", selection: $isRegisterMode) {
                    Text("Вход").tag(false)
                    Text("Регистрация").tag(true)
                }
                .pickerStyle(.segmented)

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                SecureField("Пароль", text: $password)
                    .textFieldStyle(.roundedBorder)

                if let error = authVM.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        if isRegisterMode {
                            await authVM.register(email: email, password: password)
                        } else {
                            await authVM.login(email: email, password: password)
                        }
                    }
                } label: {
                    if authVM.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(isRegisterMode ? "Создать аккаунт" : "Войти")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(authVM.isLoading)

                Spacer()
            }
            .padding()
            .navigationTitle(isRegisterMode ? "Регистрация" : "Вход")
        }
    }
}
