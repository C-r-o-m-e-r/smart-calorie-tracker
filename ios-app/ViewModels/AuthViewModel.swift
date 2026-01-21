import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @AppStorage("accessToken") private var accessToken: String = ""
    @AppStorage("refreshToken") private var refreshToken: String = ""

    @Published var isLoading = false
    @Published var errorMessage: String?

    var isAuthenticated: Bool {
        !accessToken.isEmpty
    }

    func login(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Введите email и пароль"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let token = try await AuthService.shared.login(email: email, password: password)
            accessToken = token.access_token
            refreshToken = token.refresh_token
            errorMessage = nil
        } catch {
            errorMessage = humanReadableError(error)
        }
    }

    func register(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Введите email и пароль"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await AuthService.shared.register(email: email, password: password)
            let token = try await AuthService.shared.login(email: email, password: password)
            accessToken = token.access_token
            refreshToken = token.refresh_token
            errorMessage = nil
        } catch {
            errorMessage = humanReadableError(error)
        }
    }

    func logout() {
        accessToken = ""
        refreshToken = ""
    }

    private func humanReadableError(_ error: Error) -> String {
        if let authError = error as? AuthServiceError {
            switch authError {
            case .invalidURL:
                return "Неверный адрес сервера"
            case .invalidResponse:
                return "Сервер не отвечает"
            case .server(let message):
                return message
            }
        }

        return "Ошибка входа"
    }
}
