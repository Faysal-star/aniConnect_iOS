import SwiftUI
import FirebaseAuth

struct RootView: View {
    @State private var isLoggedIn: Bool = Auth.auth().currentUser != nil
    @State private var showExtraInfo: Bool = false
    
    var body: some View {
        VStack {
            if isLoggedIn {
                if showExtraInfo {
                    ExtraInfoView(isLoggedIn: $isLoggedIn, showExtraInfo: $showExtraInfo)
                } else {
                    HomeView(isLoggedIn: $isLoggedIn)
                }
            } else {
                ContentView(isLoggedIn: $isLoggedIn)
            }
        }
        .onAppear {
            // Monitor auth state changes
            Auth.auth().addStateDidChangeListener { _, user in
                isLoggedIn = user != nil
                if let user = user {
                    checkUserProfile(userId: user.uid)
                }
            }
        }
    }
    
    private func checkUserProfile(userId: String) {
        let backendURL = "https://ani-connect-backend.vercel.app"
        guard let url = URL(string: "\(backendURL)/api/users/users/\(userId)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error checking user profile: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    return
                }
                
                showExtraInfo = httpResponse.statusCode == 404
            }
        }.resume()
    }
}

#Preview {
    RootView()
}

