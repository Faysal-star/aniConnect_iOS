import SwiftUI

struct MovieDetailView: View {
    let movie: Movie
    @Environment(\.dismiss) private var dismiss
    @State private var imageLoadError = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Backdrop/Poster Image
                if let backdropURL = movie.backdropURL, !imageLoadError {
                    AsyncImage(url: backdropURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        case .failure(_):
                            Color.gray
                                .frame(height: 200)
                                .onAppear { imageLoadError = true }
                        case .empty:
                            ProgressView()
                                .frame(height: 200)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    // Title and Rating
                    HStack {
                        Text(movie.title)
                            .font(.title)
                            .bold()
                        Spacer()
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(movie.formattedRating)
                                .bold()
                        }
                    }
                    
                    // Release Date
                    Text(movie.formattedReleaseDate)
                        .foregroundColor(.gray)
                    
                    // Overview
                    Text("Overview")
                        .font(.headline)
                        .padding(.top, 8)
                    Text(movie.overview)
                        .lineLimit(nil)
                    
                    // Additional Info
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(title: "Original Title", value: movie.originalTitle)
                        InfoRow(title: "Language", value: movie.originalLanguage.uppercased())
                        InfoRow(title: "Popularity", value: String(format: "%.1f", movie.popularity))
                        InfoRow(title: "Vote Count", value: "\(movie.voteCount)")
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
}

struct InfoRow: View {
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