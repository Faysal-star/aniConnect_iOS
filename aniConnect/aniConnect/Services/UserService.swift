import Foundation

class UserService {
    static let shared = UserService()
    private let baseURL = "https://ani-connect-backend.vercel.app/api"
    private var userCache: [String: User] = [:]
    
    func getUser(withUID uid: String) async throws -> User {
        // Check cache first
        if let cachedUser = userCache[uid] {
            return cachedUser
        }
        
        guard let url = URL(string: "\(baseURL)/users/users/\(uid)") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode != 200 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("Server error: \(errorString)")
            }
            throw URLError(.badServerResponse)
        }
        
        do {
            let decoder = JSONDecoder()
            let user = try decoder.decode(User.self, from: data)
            
            // Cache the successfully decoded user
            userCache[uid] = user
            
            return user
        } catch {
            print("Decoding error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw response: \(responseString)")
            }
            throw error
        }
    }
} 