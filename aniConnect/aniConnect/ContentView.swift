import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @Binding var isLoggedIn: Bool
    
    private let backendURL = "https://ani-connect-backend.vercel.app"
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "2193b0"),
                    Color(hex: "6dd5ed")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Content
            ScrollView {
                VStack(spacing: 30) {
                    // Logo and Title
                    VStack(spacing: 10) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("AniConnect")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 60)
                    
                    // Form Container
                    VStack(spacing: 25) {
                        // Login/Register Toggle
                        HStack(spacing: 20) {
                            Button(action: { withAnimation { isLoginMode = true }}) {
                                Text("Login")
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(isLoginMode ? .white : .white.opacity(0.5))
                            }
                            
                            Text("|")
                                .foregroundColor(.white.opacity(0.5))
                            
                            Button(action: { withAnimation { isLoginMode = false }}) {
                                Text("Register")
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(!isLoginMode ? .white : .white.opacity(0.5))
                            }
                        }
                        
                        // Form Fields
                        VStack(spacing: 20) {
                            if !isLoginMode {
                                CustomTextField(
                                    text: $name,
                                    placeholder: "Name",
                                    systemImage: "person.fill"
                                )
                            }
                            
                            CustomTextField(
                                text: $email,
                                placeholder: "Email",
                                systemImage: "envelope.fill"
                            )
                            
                            CustomTextField(
                                text: $password,
                                placeholder: "Password",
                                systemImage: "lock.fill",
                                isSecure: true
                            )
                        }
                        
                        // Error Message
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.white)
                                .font(.caption)
                                .padding(.horizontal)
                                .padding(.top, -10)
                        }
                        
                        // Action Button
                        Button(action: handleAction) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.white)
                                    .frame(height: 50)
                                    .shadow(radius: 5)
                                
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "2193b0")))
                                } else {
                                    Text(isLoginMode ? "Login" : "Register")
                                        .foregroundColor(Color(hex: "2193b0"))
                                        .font(.headline)
                                        .bold()
                                }
                            }
                        }
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 30)
                }
            }
        }
    }
    
    private func handleAction() {
        isLoading = true
        errorMessage = ""
        
        if isLoginMode {
            // Login
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    DispatchQueue.main.async {
                        isLoading = false
                        errorMessage = error.localizedDescription
                        print(error)
                    }
                    return
                }
                print(result?.user.uid)
                checkUserProfile(userId: result?.user.uid ?? "")
            }
        } else {
            // Register
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    DispatchQueue.main.async {
                        isLoading = false
                        errorMessage = error.localizedDescription
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    isLoggedIn = true
                    print("User registered")
                    isLoading = false
                }
            }
        }
    }
    
    private func checkUserProfile(userId: String) {
        guard let url = URL(string: "\(backendURL)/api/users/users/\(userId)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    print("Network Error: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    errorMessage = "Invalid response"
                    return
                }
                
                if httpResponse.statusCode == 404 {
                    // User profile doesn't exist
                    isLoggedIn = true
                } else if httpResponse.statusCode == 200 {
                    // User profile exists
                    isLoggedIn = true
                } else {
                    errorMessage = "Server error: \(httpResponse.statusCode)"
                }
            }
        }.resume()
    }
}

// Custom TextField Component
struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.white)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .autocapitalization(.none)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white.opacity(0.2))
        )
    }
}

// Color Extension for Hex Colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView(isLoggedIn: .constant(false))
}
