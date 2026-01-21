import Foundation

struct AuthTokenResponse: Decodable {
    let access_token: String
    let refresh_token: String
    let token_type: String
}

enum AuthServiceError: Error {
    case invalidURL
    case invalidResponse
    case server(String)
}

final class AuthService {
    static let shared = AuthService()

    private var baseURL: URL? {
        if let override = ProcessInfo.processInfo.environment["API_BASE_URL"],
           !override.isEmpty {
            return URL(string: override)
        }
        if let stored = UserDefaults.standard.string(forKey: "apiBaseURL"),
           !stored.isEmpty {
            return URL(string: stored)
        }
        return URL(string: "http://localhost:8000")
    }

    private init() {}

    func login(email: String, password: String) async throws -> AuthTokenResponse {
        guard let baseURL else { throw AuthServiceError.invalidURL }
        let url = baseURL.appendingPathComponent("login/access-token")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "username=\(email.urlEncoded)&password=\(password.urlEncoded)"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthServiceError.invalidResponse
        }

        if !(200...299).contains(http.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? "Ошибка сервера"
            throw AuthServiceError.server(message)
        }

        return try JSONDecoder().decode(AuthTokenResponse.self, from: data)
    }

    func register(email: String, password: String) async throws {
        guard let baseURL else { throw AuthServiceError.invalidURL }
        let url = baseURL.appendingPathComponent("users/")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthServiceError.invalidResponse
        }

        if !(200...299).contains(http.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? "Ошибка сервера"
            throw AuthServiceError.server(message)
        }
    }
}

private extension String {
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}
