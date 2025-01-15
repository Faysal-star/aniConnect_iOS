import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: String
    let role: String
    let content: String
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case role
        case content
        case timestamp
    }
    
    var isUser: Bool {
        role == "user"
    }
    
    var formattedTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = dateFormatter.date(from: timestamp) else { return "" }
        
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date)
    }
    
    // Implement Equatable
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.role == rhs.role &&
        lhs.content == rhs.content &&
        lhs.timestamp == rhs.timestamp
    }
}

struct ChatHistory: Codable {
    let messages: [ChatMessage]
} 