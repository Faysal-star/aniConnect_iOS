import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @State private var user: User?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingFavoriteMovies = false
    @State private var showingUpdateInfo = false
    
    private let backendURL = "https://ani-connect-backend.vercel.app/api"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if let user = user {
                        // Profile Header
                        VStack(spacing: 16) {
                            Text(user.fullname)
                                .font(.title)
                                .bold()
                            
                            Text(user.email)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        
                        // User Info Cards
                        VStack(spacing: 15) {
                            InfoCard(title: "Personal Information") {
                                VStack(spacing: 10) {
                                    ProfileInfoRow(title: "Age", value: "\(user.age)")
                                    ProfileInfoRow(title: "Gender", value: user.gender.capitalized)
                                    ProfileInfoRow(title: "Preferences", value: user.preferences)
                                }
                            }
                            
                            InfoCard(title: "Account Information") {
                                VStack(spacing: 10) {
                                    InfoRow(title: "Joined", value: user.formattedDate)
                                    Button(action: { showingFavoriteMovies = true }) {
                                        HStack {
                                            Text("Favorite Movies")
                                                .foregroundColor(.gray)
                                            Spacer()
                                            Text("\(user.favoriteMovies.count)")
                                                .bold()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    } else if let error = errorMessage {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                            Text(error)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.red)
                        }
                        .padding()
                    }
                    
                    // Update Info Button
                    Button(action: { showingUpdateInfo = true }) {
                        HStack {
                            Image(systemName: "pencil.circle")
                            Text("Update Info")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding()
                    
                    // Logout Button
                    Button(action: handleLogout) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Logout")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingFavoriteMovies) {
                if let user = user {
                    FavoriteMoviesView(
                        movies: user.favoriteMovies,
                        isPresented: $showingFavoriteMovies,
                        onMovieRemoved: fetchUserProfile
                    )
                }
            }
            .sheet(isPresented: $showingUpdateInfo) {
                if let user = user {
                    ExtraInfoView(
                        isLoggedIn: $isLoggedIn,
                        showExtraInfo: $showingUpdateInfo,
                        initialFullName: user.fullname,
                        initialAge: "\(user.age)",
                        initialPreferences: user.preferences,
                        initialGender: user.gender
                    )
                }
            }
            .onAppear(perform: fetchUserProfile)
        }
    }
    
    private func fetchUserProfile() {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "No user logged in"
            isLoading = false
            return
        }
        
        guard let url = URL(string: "\(backendURL)/users/users/\(currentUser.uid)") else {
            errorMessage = "Invalid URL"
            isLoading = false
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
                    self.user = try JSONDecoder().decode(User.self, from: data)
                } catch {
                    errorMessage = "Failed to decode user data"
                    print("Decoding error: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Raw response: \(responseString)")
                    }
                }
            }
        }.resume()
    }
    
    private func handleLogout() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct InfoCard<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 5)
            
            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ProfileInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .bold()
        }
    }
}

#Preview {
    ProfileView(isLoggedIn: .constant(true))
} 