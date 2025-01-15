import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: String
    let uid: String
    let email: String
    let fullname: String
    let age: Int
    let preferences: String
    let gender: String
    let favoriteMovies: [FavoriteMovie]
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case uid
        case email
        case fullname
        case age
        case preferences
        case gender
        case favoriteMovies
        case createdAt
    }
    
    var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = dateFormatter.date(from: createdAt) else { return createdAt }
        
        dateFormatter.dateFormat = "MMMM d, yyyy"
        return dateFormatter.string(from: date)
    }
}

struct FavoriteMovie: Codable, Equatable {
    let id: String
    let title: String
    let posterPath: String
    let releaseDate: String
    let rating: Double
    let movieId: String?  // Optional internal ID from MongoDB
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case rating
        case movieId = "_id"
    }
    
    var posterURL: URL? {
        URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
    
    var formattedRating: String {
        String(format: "%.1f", rating)
    }
} 