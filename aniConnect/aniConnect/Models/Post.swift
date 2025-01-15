import Foundation

struct Post: Identifiable, Codable {
    let id: String
    let uid: String
    let movie: PostMovie
    let content: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case uid
        case movie
        case content
        case createdAt
    }
    
    var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = dateFormatter.date(from: createdAt) else { return createdAt }
        
        dateFormatter.dateFormat = "MMM d, yyyy"
        return dateFormatter.string(from: date)
    }
}

struct PostMovie: Codable {
    let id: String
    let title: String
    let posterPath: String
    let releaseDate: String
    let rating: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case rating
    }
    
    var posterURL: URL? {
        URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
    
    var formattedRating: String {
        String(format: "%.1f", rating)
    }
} 