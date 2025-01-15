import SwiftUI
import FirebaseAuth

struct FavoriteButton: View {
    let movieId: Int
    @State private var isLoading = false
    @State private var isFavorited = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let backendURL = "https://ani-connect-backend.vercel.app/api"
    
    var body: some View {
        Button(action: toggleFavorite) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 32, height: 32)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .foregroundColor(isFavorited ? .red : .white)
                        .font(.system(size: 15))
                }
            }
        }
        .disabled(isLoading)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            checkIfFavorited()
        }
    }
    
    private func toggleFavorite() {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "Please login to manage favorites"
            showError = true
            return
        }
        
        isLoading = true
        
        let endpoint = isFavorited ? "/movies/removeFav" : "/movies/addFav"
        let requestBody: [String: Any] = [
            "uid": currentUser.uid,
            "movieId": movieId
        ]
        
        guard let url = URL(string: "\(backendURL)\(endpoint)"),
              let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    showError = true
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        isFavorited.toggle()
                    } else {
                        errorMessage = isFavorited ? 
                            "Failed to remove from favorites" : 
                            "Failed to add to favorites"
                        showError = true
                    }
                }
            }
        }.resume()
    }
    
    private func checkIfFavorited() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        guard let url = URL(string: "\(backendURL)/users/users/\(currentUser.uid)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let user = try JSONDecoder().decode(User.self, from: data)
                    DispatchQueue.main.async {
                        isFavorited = user.favoriteMovies.contains { $0.id == String(movieId) }
                    }
                } catch {
                    print("Error checking favorites: \(error)")
                }
            }
        }.resume()
    }
} 