import SwiftUI
import FirebaseAuth

struct ChatView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Bar
                CustomTabBar(selectedTab: $selectedTab)
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    AIRecommenderView()
                        .tag(0)
                    
                    AIChatView()
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle(selectedTab == 0 ? "AI Recommender" : "Chat")
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabButton(title: "AI Recommender", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            TabButton(title: "Chat", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
} 