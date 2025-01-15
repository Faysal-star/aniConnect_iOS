import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        TabView {
            HomePageView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            ForumView()
                .tabItem {
                    Label("Forum", systemImage: "bubble.left.and.bubble.right")
                }
            
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message")
                }
            
            ProfileView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
    
    private func handleLogout() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

struct HomePageView: View {
    @State private var searchText: String = ""
    @State private var currentSearchQuery: String = ""
    @State private var topMovies: [Movie] = []
    @State private var actionMovies: [Movie] = []
    @State private var dramaMovies: [Movie] = []
    @State private var showingSearchResults = false
    @State private var showingMoreMovies = false
    @State private var selectedGenre: (title: String, id: Int?) = ("", nil)
    
    private let backendURL = "https://ani-connect-backend.vercel.app/api/movies"
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText, onSearchButtonClicked: performSearch)
                
                ScrollView {
                    VStack(alignment: .leading) {
                        if !topMovies.isEmpty {
                            MovieSectionView(
                                title: "Top Movies",
                                movies: topMovies,
                                genreID: nil,
                                onShowMore: { showMoreMovies(title: "Top Movies", genreId: nil) }
                            )
                        }
                        
                        if !actionMovies.isEmpty {
                            MovieSectionView(
                                title: "Action",
                                movies: actionMovies,
                                genreID: 28,
                                onShowMore: { showMoreMovies(title: "Action Movies", genreId: 28) }
                            )
                        }
                        
                        if !dramaMovies.isEmpty {
                            MovieSectionView(
                                title: "Drama",
                                movies: dramaMovies,
                                genreID: 18,
                                onShowMore: { showMoreMovies(title: "Drama Movies", genreId: 18) }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Movies")
        }
        .sheet(isPresented: $showingSearchResults) {
            MovieGridView(
                title: "Search Results",
                genreId: nil,
                searchQuery: currentSearchQuery,
                isPresented: $showingSearchResults
            )
        }
        .sheet(isPresented: $showingMoreMovies) {
            MovieGridView(
                title: selectedGenre.title,
                genreId: selectedGenre.id,
                searchQuery: nil,
                isPresented: $showingMoreMovies
            )
        }
        .onChange(of: showingSearchResults) { newValue in
            if !newValue {
                searchText = ""
                currentSearchQuery = ""
            }
        }
        .onAppear {
            fetchMovies()
        }
    }
    
    private func performSearch() {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return }
        
        showingMoreMovies = false
        currentSearchQuery = trimmedSearch
        print("HomePageView searchText: \(currentSearchQuery)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showingSearchResults = true
        }
    }
    
    private func fetchMovies() {
        fetchMovies(from: "\(backendURL)/top") { movies in
            self.topMovies = movies
        }
        fetchMovies(from: "\(backendURL)/genre/28") { movies in
            self.actionMovies = movies
        }
        fetchMovies(from: "\(backendURL)/genre/18") { movies in
            self.dramaMovies = movies
        }
    }
    
    private func fetchMovies(from urlString: String, completion: @escaping ([Movie]) -> Void) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching movies: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                do {
                    let movies = try JSONDecoder().decode([Movie].self, from: data)
                    DispatchQueue.main.async {
                        print("Fetched \(movies.count) movies from \(urlString)")
                        completion(movies)
                    }
                } catch {
                    print("Error decoding movies: \(error)")
                }
            } else {
                print("No data received from \(urlString)")
            }
        }.resume()
    }
    
    private func showMoreMovies(title: String, genreId: Int?) {
        if !showingSearchResults {
            self.selectedGenre = (title, genreId)
            self.showingMoreMovies = true
        }
    }
}

struct MovieSectionView: View {
    let title: String
    let movies: [Movie]
    let genreID: Int?
    let onShowMore: () -> Void
    @State private var selectedMovie: Movie?
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button("See More") {
                    onShowMore()
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(movies) { movie in
                        MovieCard(movie: movie)
                            .onTapGesture {
                                selectedMovie = movie
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .sheet(item: $selectedMovie) { movie in
            NavigationView {
                MovieDetailView(movie: movie)
            }
        }
    }
}

struct MovieCard: View {
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
                                .frame(width: 100, height: 150)
                                .clipped()
                        case .failure(_):
                            Rectangle()
                                .fill(Color.gray)
                                .frame(width: 100, height: 150)
                        case .empty:
                            ProgressView()
                                .frame(width: 100, height: 150)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                FavoriteButton(movieId: movie.id)
                    .padding(4)
            }
            
            Text(movie.title)
                .font(.caption)
                .lineLimit(2)
                .frame(width: 100)
        }
    }
}

struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    var onSearchButtonClicked: () -> Void
    
    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        var onSearchButtonClicked: () -> Void
        
        init(text: Binding<String>, onSearchButtonClicked: @escaping () -> Void) {
            _text = text
            self.onSearchButtonClicked = onSearchButtonClicked
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            onSearchButtonClicked()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, onSearchButtonClicked: onSearchButtonClicked)
    }
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}

#Preview {
    HomeView(isLoggedIn: .constant(true))
} 
