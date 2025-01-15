import SwiftUI
import FirebaseAuth

struct AIChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var newMessage: String = ""
    @State private var isLoading = false
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var lastMessageId: String? = nil
    
    private let backendURL = "https://ani-connect-backend.vercel.app/api"
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if isLoading {
                            ProgressView()
                                .padding()
                        }
                    }
                    .padding()
                }
                .onAppear {
                    scrollProxy = proxy
                    fetchChatHistory()
                }
                .onChange(of: messages) { _ in
                    if let lastId = messages.last?.id {
                        scrollProxy?.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
            
            // Message Input
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $newMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(isLoading)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(newMessage.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(20)
                    }
                    .disabled(newMessage.isEmpty || isLoading)
                }
                .padding()
            }
            .background(Color(.systemBackground))
        }
    }
    
    private func fetchChatHistory() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        guard let url = URL(string: "\(backendURL)/chat/history/\(currentUser.uid)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching chat history: \(error)")
                return
            }
            
            guard let data = data else { return }
            
            do {
                let history = try JSONDecoder().decode(ChatHistory.self, from: data)
                DispatchQueue.main.async {
                    messages = history.messages
                }
            } catch {
                print("Error decoding chat history: \(error)")
            }
        }.resume()
    }
    
    private func sendMessage() {
        guard let currentUser = Auth.auth().currentUser else { return }
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = newMessage
        newMessage = ""
        isLoading = true
        
        let requestBody: [String: Any] = [
            "uid": currentUser.uid,
            "message": message
        ]
        
        guard let url = URL(string: "\(backendURL)/chat/continue"),
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
                    print("Error sending message: \(error)")
                    return
                }
                
                guard let data = data else { return }
                
                do {
                    // After sending message, fetch updated history
                    fetchChatHistory()
                } catch {
                    print("Error processing response: \(error)")
                }
            }
        }.resume()
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading) {
                Text(message.content)
                    .padding(12)
                    .background(message.isUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(20)
                    .cornerRadius(message.isUser ? 20 : 20,
                                corners: message.isUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
                
                Text(message.formattedTime)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            
            if !message.isUser { Spacer() }
        }
        .padding(.horizontal, 4)
    }
}

// Helper for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                               byRoundingCorners: corners,
                               cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
} 