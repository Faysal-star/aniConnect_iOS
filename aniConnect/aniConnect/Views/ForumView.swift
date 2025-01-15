import SwiftUI
import FirebaseAuth

struct ForumView: View {
    @State private var posts: [Post] = []
    @State private var showingCreatePost = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let backendURL = "https://ani-connect-backend.vercel.app/api"
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if posts.isEmpty {
                        Text("No posts yet")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(posts) { post in
                            PostCard(post: post)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Forum")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreatePost = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingCreatePost) {
                CreatePostView(isPresented: $showingCreatePost, onPostCreated: fetchPosts)
            }
        }
        .onAppear(perform: fetchPosts)
    }
    
    private func fetchPosts() {
        isLoading = true
        
        guard let url = URL(string: "\(backendURL)/posts/posts") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No data received"
                    return
                }
                
                do {
                    posts = try JSONDecoder().decode([Post].self, from: data)
                } catch {
                    errorMessage = "Failed to decode posts"
                    print("Decoding error: \(error)")
                }
            }
        }.resume()
    }
}

struct PostCard: View {
    let post: Post
    @State private var username: String = "Loading..."
    @State private var loadingError: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Movie Poster
            if let posterURL = post.movie.posterURL {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 120)
                            .cornerRadius(8)
                    case .failure(_):
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 80, height: 120)
                            .cornerRadius(8)
                    case .empty:
                        ProgressView()
                            .frame(width: 80, height: 120)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            // Post Content
            VStack(alignment: .leading, spacing: 8) {
                Text(post.movie.title)
                    .font(.headline)
                    .lineLimit(2)
                
                // User and Date
                HStack {
                    Text(username)
                        .fontWeight(.medium)
                    Text("•")
                    Text(post.formattedDate)
                }
                .font(.caption)
                .foregroundColor(.gray)
                
                // Rating
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(post.movie.formattedRating)
                }
                .font(.caption)
                
                Text(post.content)
                    .font(.body)
                    .lineLimit(4)
                
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .task {
            do {
                let user = try await UserService.shared.getUser(withUID: post.uid)
                username = user.fullname
            } catch {
                print("Error fetching user: \(error)")
                username = "Unknown User"
                loadingError = true
            }
        }
    }
} 