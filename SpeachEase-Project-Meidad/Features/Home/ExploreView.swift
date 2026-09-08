import SwiftUI

struct ExploreView: View {
    @State private var searchText = ""

    @State private var blobAnimation = false
    @ObservedObject var learningManager = LearningManager.shared // Observe progress
    
    var body: some View {
        NavigationStack {
            ExploreContent()
        }
    }
}

struct ExploreContent: View {
    @State private var searchText = ""


    @State private var blobAnimation = false
    @ObservedObject var learningManager = LearningManager.shared
    @Environment(\.horizontalSizeClass) var sizeClass
    @State private var availableWidth: CGFloat = 0
    @State private var showResetAlert = false

    var body: some View {
        ZStack {
            // Base Background
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            // Foggy Gradient Animation

                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text("Explore")
                            .font(.system(size: 34, weight: .bold))
                            .padding(.horizontal)
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Search topics...", text: $searchText)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        
                        // Filter Tags
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                let filters = ["All", "Popular", "New", "Beginner", "Advanced"]
                                ForEach(filters, id: \.self) { filter in
                                    Text(filter)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(filter == "All" ? Color.blue : Color.blue.opacity(0.1))
                                        .foregroundStyle(filter == "All" ? .white : .blue)
                                        .clipShape(Capsule())
