import SwiftUI
import FirebaseAuth

struct CreatePostView: View {
    @Binding var isPresented: Bool
    let onPostCreated: () -> Void
    
    @State private var searchText = ""
    @State private var selectedMovie: Movie?
    @State private var content = ""
    @State private var searchResults: [Movie] = []
    @State private var isSearching = false
    @State private var isPosting = false
    @State private var errorMessage: String?
    
    private let backendURL = "https://ani-connect-backend.vercel.app/api"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Movie Search
                if selectedMovie == nil {
                    SearchBar(text: $searchText, onSearchButtonClicked: searchMovies)
                    
                    if isSearching {
                        ProgressView()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(searchResults) { movie in
                                    MovieSearchRow(movie: movie)
                                        .onTapGesture {
                                            selectedMovie = movie
                                        }
                                }
                            }
                            .padding()
                        }
                    }
                } else {
                    // Selected Movie and Review
                    SelectedMovieView(movie: selectedMovie!) {
                        selectedMovie = nil
                    }
                    
                    TextEditor(text: $content)
                        .frame(height: 150)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Create Post")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Post") {
                    createPost()
                }
                .disabled(selectedMovie == nil || content.isEmpty || isPosting)
            )
        }
    }
    
    private func searchMovies() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        searchResults = []
        
        let query = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "\(backendURL)/movies/search?query=\(query)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isSearching = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else { return }
                
                do {
                    searchResults = try JSONDecoder().decode([Movie].self, from: data)
                } catch {
                    errorMessage = "Failed to decode search results"
                }
            }
        }.resume()
    }
    
    private func createPost() {
        guard let currentUser = Auth.auth().currentUser,
              let movie = selectedMovie else { return }
        
        let postMovie = PostMovie(
            id: String(movie.id),
            title: movie.title,
            posterPath: movie.posterPath ?? "",
            releaseDate: movie.releaseDate,
            rating: movie.voteAverage
        )
        
        let post = [
            "uid": currentUser.uid,
            "movie": [
                "id": postMovie.id,
                "title": postMovie.title,
                "poster_path": postMovie.posterPath,
                "release_date": postMovie.releaseDate,
                "rating": postMovie.rating
            ],
            "content": content
        ] as [String : Any]
        
        guard let url = URL(string: "\(backendURL)/posts/posts"),
              let jsonData = try? JSONSerialization.data(withJSONObject: post) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        isPosting = true
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isPosting = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    onPostCreated()
                    isPresented = false
                } else {
                    errorMessage = "Failed to create post"
                }
            }
        }.resume()
    }
}

struct MovieSearchRow: View {
    let movie: Movie
    
    var body: some View {
        HStack(spacing: 12) {
            if let posterURL = movie.posterURL {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 90)
                            .cornerRadius(6)
                    case .failure(_):
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 60, height: 90)
                            .cornerRadius(6)
                    case .empty:
                        ProgressView()
                            .frame(width: 60, height: 90)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.headline)
                
                Text(movie.formattedReleaseDate)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(movie.formattedRating)
                }
                .font(.caption)
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

struct SelectedMovieView: View {
    let movie: Movie
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            if let posterURL = movie.posterURL {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 90)
                            .cornerRadius(6)
                    case .failure(_):
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 60, height: 90)
                            .cornerRadius(6)
                    case .empty:
                        ProgressView()
                            .frame(width: 60, height: 90)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.headline)
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(movie.formattedRating)
                }
                .font(.caption)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
} 