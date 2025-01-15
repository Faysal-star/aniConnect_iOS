import SwiftUI
import FirebaseAuth

struct FavoriteMoviesView: View {
    let movies: [FavoriteMovie]
    @Binding var isPresented: Bool
    @State private var selectedMovie: Movie?
    @Environment(\.dismiss) private var dismiss
    let onMovieRemoved: () -> Void
    
    var body: some View {
        FavoriteMoviesContent(
            movies: movies,
            isPresented: $isPresented,
            selectedMovie: $selectedMovie,
            onRemoveSuccess: { dismiss() },
            onMovieRemoved: onMovieRemoved
        )
        .sheet(item: $selectedMovie) { movie in
            NavigationView {
                MovieDetailView(movie: movie)
            }
        }
    }
}

// Separated content view
struct FavoriteMoviesContent: View {
    let movies: [FavoriteMovie]
    @Binding var isPresented: Bool
    @Binding var selectedMovie: Movie?
    let onRemoveSuccess: () -> Void
    let onMovieRemoved: () -> Void
    
    private let gridItems = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: gridItems, spacing: 20) {
                    ForEach(movies, id: \.id) { favMovie in
                        FavoriteMovieCard(
                            movie: favMovie,
                            onRemoved: onMovieRemoved
                        )
                            .onTapGesture {
                                selectedMovie = convertToMovie(favMovie)
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Favorite Movies")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Close") {
                isPresented = false
            })
        }
    }
    
    private func convertToMovie(_ favMovie: FavoriteMovie) -> Movie {
        Movie(
            id: Int(favMovie.id) ?? 0,
            title: favMovie.title,
            originalTitle: favMovie.title,
            overview: "",
            posterPath: favMovie.posterPath,
            backdropPath: nil,
            releaseDate: favMovie.releaseDate,
            voteAverage: favMovie.rating,
            voteCount: 0,
            popularity: 0,
            genreIds: [],
            adult: false,
            originalLanguage: "en",
            video: false
        )
    }
}

// Separated card view
struct FavoriteMovieCard: View {
    let movie: FavoriteMovie
    let onRemoved: () -> Void
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let backendURL = "https://ani-connect-backend.vercel.app/api"
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) {
                MoviePosterView(posterURL: movie.posterURL)
                
                // Remove button
                Button(action: removeFromFavorites) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 32, height: 32)
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 15))
                        }
                    }
                }
                .disabled(isLoading)
                .padding(8)
            }
            
            MovieInfoView(title: movie.title, rating: movie.formattedRating)
        }
        .frame(width: 150)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func removeFromFavorites() {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "Please login to remove favorites"
            showError = true
            return
        }
        
        isLoading = true
        
        let requestBody: [String: Any] = [
            "uid": currentUser.uid,
            "movieId": Int(movie.id) ?? 0
        ]
        
        guard let url = URL(string: "\(backendURL)/movies/removefav"),
              let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
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
                        onRemoved()
                    } else {
                        errorMessage = "Failed to remove from favorites"
                        showError = true
                    }
                }
            }
        }.resume()
    }
}

// Poster view component
struct MoviePosterView: View {
    let posterURL: URL?
    
    var body: some View {
        if let url = posterURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 225)
                        .clipped()
                case .failure(_):
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 150, height: 225)
                case .empty:
                    ProgressView()
                        .frame(width: 150, height: 225)
                @unknown default:
                    EmptyView()
                }
            }
        }
    }
}

// Movie info view component
struct MovieInfoView: View {
    let title: String
    let rating: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .bold()
                .lineLimit(2)
            
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
                Text(rating)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 4)
    }
} 
