import SwiftUI

struct MovieGridView: View {
    let title: String
    let searchQuery: String?
    let genreId: Int?
    
    private var viewType: ViewType
    
    @Binding var isPresented: Bool
    @State private var movies: [Movie] = []
    @State private var selectedMovie: Movie?
    @State private var isLoading = false
    
    private let backendURL = "https://ani-connect-backend.vercel.app/api/movies"
    private let gridItems = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    enum ViewType {
        case search
        case genre
        case top
    }
    
    init(title: String, genreId: Int? = nil, searchQuery: String? = nil, isPresented: Binding<Bool>) {
        self.title = title
        self.genreId = genreId
        self.searchQuery = searchQuery
        self._isPresented = isPresented
        
        if let query = searchQuery, !query.isEmpty {
            self.viewType = .search
        } else if genreId != nil {
            self.viewType = .genre
        } else {
            self.viewType = .top
        }
    }
    
    private var navigationTitle: String {
        if case .search = viewType, let query = searchQuery, !query.isEmpty {
            return "Results for '\(query)'"
        }
        return title
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if movies.isEmpty {
                        Text("No movies available")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        LazyVGrid(columns: gridItems, spacing: 20) {
                            ForEach(movies) { movie in
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
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Close") {
                isPresented = false
            })
        }
        .sheet(item: $selectedMovie) { movie in
            NavigationView {
                MovieDetailView(movie: movie)
            }
        }
        .onAppear {
            print("MovieGridView appeared with searchQuery: \(searchQuery ?? "nil")")
            fetchMovies()
        }
    }
    
    private func fetchMovies() {
        isLoading = true
        var urlString = backendURL
        
        print("MovieGridView fetching with searchQuery: \(searchQuery ?? "nil")")
        
        switch viewType {
        case .search:
            if let query = searchQuery, !query.isEmpty {
                let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                urlString += "/search?query=\(encodedQuery)"
                print("Search URL: \(urlString)")
            }
        case .genre:
            if let genreId = genreId {
                urlString += "/genre/\(genreId)"
            }
        case .top:
            urlString += "/top"
        }
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            isLoading = false
            return
        }
        
        print("Fetching movies from: \(urlString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("Error fetching movies: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Response status code: \(httpResponse.statusCode)")
                }
                
                if let data = data {
                    do {
                        let fetchedMovies = try JSONDecoder().decode([Movie].self, from: data)
                        self.movies = fetchedMovies
                        print("Fetched \(fetchedMovies.count) movies for query: \(searchQuery ?? "no query")")
                    } catch {
                        print("Error decoding movies: \(error)")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("Raw response: \(responseString)")
                        }
                    }
                } else {
                    print("No data received")
                }
            }
        }.resume()
    }
}

struct MovieGridCard: View {
    let movie: Movie
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) {
                if let posterURL = movie.posterURL {
                    AsyncImage(url: posterURL) { phase in
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
                
                FavoriteButton(movieId: movie.id)
                    .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.subheadline)
                    .bold()
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text(movie.formattedRating)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 150)
    }
} 
