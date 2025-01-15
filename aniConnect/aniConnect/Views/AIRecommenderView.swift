import SwiftUI
import FirebaseAuth

struct AIRecommenderView: View {
    @State private var feeling = ""
    @State private var movieType = ""
    @State private var genre = ""
    @State private var isLoading = false
    @State private var recommendedMovies: [Movie] = []
    @State private var errorMessage: String?
    @State private var selectedMovie: Movie?
    
    private let backendURL = "https://ani-connect-backend.vercel.app/api"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Input Fields
                VStack(alignment: .leading, spacing: 16) {
                    InputField(title: "How are you feeling?", text: $feeling)
                    InputField(title: "What type of movie you are willing to see?", text: $movieType)
                    InputField(title: "Any specific genre?", text: $genre)
                }
                .padding()
                
                // Get Recommendations Button
                Button(action: getRecommendations) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Get Recommendations")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(isLoading || !isInputValid)
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Recommended Movies Grid
                if !recommendedMovies.isEmpty {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 150), spacing: 16)
                    ], spacing: 16) {
                        ForEach(recommendedMovies) { movie in
                            MovieGridCard(movie: movie)
                                .onTapGesture {
                                    selectedMovie = movie
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $selectedMovie) { movie in
            NavigationView {
                MovieDetailView(movie: movie)
            }
        }
    }
    
    private var isInputValid: Bool {
        !feeling.isEmpty && !movieType.isEmpty && !genre.isEmpty
    }
    
    private func getRecommendations() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Create structured prompt
        let prompt = """
        Feeling: \(feeling)
        Movie Type: \(movieType)
        Genre: \(genre)
        Please recommend movies based on these preferences.
        """
        
        let requestBody: [String: Any] = [
            "uid": currentUser.uid,
            "message": prompt
        ]
        
        guard let url = URL(string: "\(backendURL)/chat/recommend"),
              let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                handleError("Network error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                handleError("No data received")
                return
            }
            
            do {
                let movieTitles = try JSONDecoder().decode([String].self, from: data)
                searchMovies(titles: movieTitles)
            } catch {
                handleError("Failed to decode recommendations")
            }
        }.resume()
    }
    
    private func searchMovies(titles: [String]) {
        let group = DispatchGroup()
        var movies: [Movie] = []
        
        for title in titles {
            group.enter()
            
            let query = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            guard let url = URL(string: "\(backendURL)/movies/search?query=\(query)") else {
                group.leave()
                continue
            }
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                defer { group.leave() }
                
                if let data = data,
                   let searchResults = try? JSONDecoder().decode([Movie].self, from: data),
                   let movie = searchResults.first {
                    movies.append(movie)
                }
            }.resume()
        }
        
        group.notify(queue: .main) {
            isLoading = false
            recommendedMovies = movies
            if movies.isEmpty {
                errorMessage = "No movies found"
            }
        }
    }
    
    private func handleError(_ message: String) {
        DispatchQueue.main.async {
            isLoading = false
            errorMessage = message
        }
    }
}

struct InputField: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            TextField("Enter your response", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
} 