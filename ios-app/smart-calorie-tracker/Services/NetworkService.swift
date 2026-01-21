import Foundation
import UIKit

// --- MODELS ---

struct TokenResponse: Codable {
    let access_token: String
    let token_type: String
}

struct UserCreate: Codable {
    let email: String
    let password: String
    let full_name: String?
}

struct UserResponse: Codable {
    let id: Int
    let email: String
    let full_name: String?
}

// Model for saving a meal to the server
struct MealCreate: Codable {
    let name: String
    let calories: Int
    let protein: Double
    let fats: Double
    let carbs: Double
    let weight_grams: Double
}

// AI Analysis Response
struct AIAnalysisResponse: Codable {
    let name: String
    let calories: Int
    let protein: Double
    let fats: Double
    let carbs: Double
    let weight_grams: Double
    let is_food: Bool
    let image_path: String?
}

struct ChatResponse: Decodable {
    let reply: String
}

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case unauthorized
    case serverError(String)
}

// --- SERVICE ---

class NetworkService {
    static let shared = NetworkService()
    
    // Store token here
    var authToken: String?
    
    private init() {}
    
    // MARK: - 1. LOGIN
    func login(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(AppConfig.baseURL)/login/access-token") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "username=\(email)&password=\(password)"
        request.httpBody = bodyString.data(using: .utf8)
        
        print("🔑 Logging in...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NetworkError.noData)); return }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                print("❌ Login Failed. Status: \(httpResponse.statusCode)")
                completion(.failure(NetworkError.unauthorized))
                return
            }
            
            do {
                let tokenObj = try JSONDecoder().decode(TokenResponse.self, from: data)
                self.authToken = tokenObj.access_token
                print("✅ Token received!")
                completion(.success(tokenObj.access_token))
            } catch {
                print("❌ Login Decode Error: \(error)")
                completion(.failure(NetworkError.decodingError))
            }
        }.resume()
    }
    
    // MARK: - 2. REGISTER
    func register(email: String, password: String, name: String, completion: @escaping (Result<UserResponse, Error>) -> Void) {
        guard let url = URL(string: "\(AppConfig.baseURL)/users/") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let newUser = UserCreate(email: email, password: password, full_name: name)
        request.httpBody = try? JSONEncoder().encode(newUser)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { return }
            
            do {
                let createdUser = try JSONDecoder().decode(UserResponse.self, from: data)
                completion(.success(createdUser))
            } catch {
                completion(.failure(NetworkError.decodingError))
            }
        }.resume()
    }

    // MARK: - 3. ANALYZE FOOD
    func analyzeImage(image: UIImage, completion: @escaping (Result<AIAnalysisResponse, Error>) -> Void) {
        guard let url = URL(string: "\(AppConfig.baseURL)/meals/analyze") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        print("🚀 Sending image to: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            print("⚠️ Warning: Sending image without Auth Token")
        }
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"meal.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network Error: \(error.localizedDescription)")
                completion(.failure(NetworkError.serverError("Connection failed. Check IP.")))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Server responded with Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 401 {
                    print("❌ Unauthorized. Please login again.")
                    completion(.failure(NetworkError.unauthorized))
                    return
                }
                
                if httpResponse.statusCode != 200 {
                    let serverMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
                    print("❌ Server Error Body: \(serverMsg)")
                    completion(.failure(NetworkError.serverError("Server Error \(httpResponse.statusCode)")))
                    return
                }
            }
            
            do {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("✅ Received JSON: \(jsonString)")
                }
                let result = try JSONDecoder().decode(AIAnalysisResponse.self, from: data)
                completion(.success(result))
            } catch {
                print("❌ JSON Decode Error: \(error)")
                completion(.failure(NetworkError.decodingError))
            }
        }.resume()
    }
    
    // MARK: - 4. CHAT
    func sendChatMessage(message: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(AppConfig.baseURL)/chat/") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["message": message]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { return }
            
            do {
                let result = try JSONDecoder().decode(ChatResponse.self, from: data)
                completion(.success(result.reply))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - 5. CREATE MEAL (SAVE TO SERVER)
    func createMeal(name: String, calories: Int, protein: Double, fats: Double, carbs: Double, weight: Double, completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard let url = URL(string: "\(AppConfig.baseURL)/meals/") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add Authorization Token
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let newMeal = MealCreate(
            name: name,
            calories: calories,
            protein: protein,
            fats: fats,
            carbs: carbs,
            weight_grams: weight
        )
        
        request.httpBody = try? JSONEncoder().encode(newMeal)
        
        print("💾 Sending meal to server: \(name)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    print("✅ Meal saved on server!")
                    completion(.success(()))
                } else {
                    print("❌ Server Error: \(httpResponse.statusCode)")
                    completion(.failure(NetworkError.serverError("Status \(httpResponse.statusCode)")))
                }
            }
        }.resume()
    }
}
