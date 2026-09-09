import SwiftUI
import PhotosUI

struct AccountView: View {
    @ObservedObject var profileManager = UserProfileManager.shared
    
    var body: some View {
        NavigationStack {
            if profileManager.isOnboardingCompleted {
                AccountProfileView()
            } else {
                AccountOnboardingView()
            }
        }
    }
}

// MARK: - Onboarding / Edit View
struct AccountOnboardingView: View {
    @ObservedObject var profileManager = UserProfileManager.shared
    @Environment(\.dismiss) var dismiss // To close if presented as sheet
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var isEditing: Bool = false // Mode flag
    
    @State private var fn = ""
    @State private var ln = ""
    @State private var dn = ""
    @State private var bio = ""
    @State private var useDn = false
    @State private var color: Color = .purple
    
    // Photo Picker State
    @State private var selectedItem: PhotosPickerItem?
    
    // Preset Palette
    let colors: [Color] = [.purple, .blue, .mint, .green, .orange, .pink, .red, .indigo]
    
    var body: some View {
        ZStack {
            // Simple Clean Background
            LinearGradient(colors: [.white, color.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            // Content Container
            VStack(spacing: 0) {
                // Header (Dynamic Avatar)
                VStack(spacing: 16) {
                    // Avatar Selection
                    AvatarPickerButton(
                        image: profileManager.profileImage,
                        color: color,
                        selection: $selectedItem
                    )
                    .padding(.top, 40)
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                // Save directly, skipping crop
                                profileManager.saveProfileImage(uiImage)
                            }
                        }
                    }
                    
                    if !isEditing {
                        VStack(spacing: 8) {
                            Text("Create Profile")
                                .font(.system(size: 32, weight: .bold))
                            
                            Text("Customize your Speechease experience.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Edit Profile")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                }
                .padding(.bottom, 20)
                
                // Form Container
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Name Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Identifying Details")
                                    .font(.caption).fontWeight(.bold).foregroundStyle(.secondary)
                                Spacer()
                                Text("\(fn.count + ln.count)/15")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle((fn.count + ln.count) >= 15 ? .red : .secondary)
                            }
                            
                            HStack {
                                Image(systemName: "person.fill").foregroundStyle(.secondary)
                                TextField("First Name", text: $fn)
                                    .onChange(of: fn) { _, newValue in
                                        let available = 15 - ln.count
                                        if newValue.count > available {
                                            fn = String(newValue.prefix(max(0, available)))
                                        }
                                    }
                            }
                            .padding()
                            .background(Color(uiColor: .secondarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: (fn.count + ln.count) >= 15 ? 1 : 0)
                            )
                            .cornerRadius(12)
                            
                            HStack {
                                Image(systemName: "person.fill").foregroundStyle(.secondary)
                                TextField("Last Name", text: $ln)
                                    .onChange(of: ln) { _, newValue in
                                        let available = 15 - fn.count
                                        if newValue.count > available {
                                            ln = String(newValue.prefix(max(0, available)))
                                        }
                                    }
                            }
                            .padding()
                            .background(Color(uiColor: .secondarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: (fn.count + ln.count) >= 15 ? 1 : 0)
                            )
                            .cornerRadius(12)
                        }
                        
                        // Display Name Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Public Display")
                                .font(.caption).fontWeight(.bold).foregroundStyle(.secondary)
                            
                            HStack {
                                Image(systemName: "at").foregroundStyle(.secondary)
                                TextField("Display Name (Pseudo)", text: $dn)
                            }
                            .padding()
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(12)
                            
                            Toggle(isOn: $useDn) {
                                Text("Use Display Name")
                                    .fontWeight(.medium)
                            }
                            .tint(color)
                            .padding(.horizontal, 4)
                        }
                        
                        // Bio Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Short Bio (Max 20 chars)")
                                .font(.caption).fontWeight(.bold).foregroundStyle(.secondary)
                            
                            HStack {
                                Image(systemName: "text.quote")
                                    .foregroundStyle(.secondary)
                                TextField("Speechease Student", text: $bio)
                                    .onChange(of: bio) { _, newValue in
                                        if newValue.count > 20 {
                                            bio = String(newValue.prefix(20))
                                        }
                                    }
                            }
                            .padding()
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(12)
                            
                            Text("\(bio.count)/20")
                                .font(.caption2)
                                .foregroundStyle(bio.count == 20 ? .red : .secondary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        
                        // Color Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Theme Color")
                                .font(.caption).fontWeight(.bold).foregroundStyle(.secondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                                ForEach(colors, id: \.self) { c in
                                    Circle()
                                        .fill(c.gradient)
                                        .frame(height: 50)
                                        .overlay(
                                            Image(systemName: "checkmark")
                                                .font(.headline)
                                                .foregroundStyle(.white)
                                                .opacity(color == c ? 1 : 0)
                                        )
                                        .shadow(color: c.opacity(0.3), radius: 6, y: 3)
                                        .onTapGesture {
                                            withAnimation(.spring()) { color = c }
                                        }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                
                // Footer Action
                Button {
                    profileManager.saveProfile(first: fn, last: ln, display: dn, useDisplay: useDn, color: color, bio: bio)
                    if isEditing { dismiss() }
                } label: {
                    HStack {
                        Text(isEditing ? "Save Changes" : "Get Started")
                        if !isEditing { Image(systemName: "arrow.right") }
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(color.gradient)
                    .cornerRadius(28)
                    .shadow(color: color.opacity(0.4), radius: 10, y: 5)
                }
                .padding()
                .padding(.bottom, 10)
                .disabled(fn.isEmpty || ln.isEmpty)
                .opacity(fn.isEmpty || ln.isEmpty ? 0.6 : 1)
            }
            .background(
                // Card Background for iPad
                RoundedRectangle(cornerRadius: sizeClass == .regular ? 24 : 0)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
                    .opacity(sizeClass == .regular ? 1 : 0) // Hide on iPhone, effectively transparent
            )
            .padding(sizeClass == .regular ? 40 : 0) // Margin from edges on iPad
            .frame(maxWidth: sizeClass == .regular ? 550 : .infinity) // Constrain width on iPad
            .frame(maxHeight: sizeClass == .regular ? 800 : .infinity) // Constrain height slightly
        }
        .onAppear {
            if isEditing || !profileManager.firstName.isEmpty {
                fn = profileManager.firstName
                ln = profileManager.lastName
                dn = profileManager.displayName
                bio = profileManager.bio
                useDn = profileManager.useDisplayName
                color = profileManager.favoriteColor
            }
        }
    }
}

// MARK: - Profile View
struct AccountProfileView: View {
    @ObservedObject var profileManager = UserProfileManager.shared
    @State private var showSettings = false
    @State private var showYearlyHistory = false
    @State private var settingsDetent = PresentationDetent.large
    // Stats State
    @State private var totalSessions: Int = 0
    @State private var currentStreak: Int = 0
    @State private var topFocus: String = "None"
    @State private var dailySessions: [Date: [PracticeSession]] = [:]

    @State private var selectedDateWrapper: DateWrapper? // For sheet
    @State private var globalHistory: [PracticeAttempt] = []
    @State private var sessionNameMap: [UUID: String] = [:] // Map for graph
    
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // 1. Header
                HStack(alignment: .center, spacing: 20) {
                     // Avatar
                    if let img = profileManager.profileImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.green.opacity(0.5), lineWidth: 3))
                            .shadow(color: .green.opacity(0.3), radius: 10)
                    } else {
                         Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundStyle(.gray)
                            .frame(width: 90, height: 90)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        let rawName = profileManager.useDisplayName && !profileManager.displayName.isEmpty 
                            ? profileManager.displayName 
                            : "\(profileManager.firstName) \(profileManager.lastName)"
                        let name = String(rawName.prefix(15))
                        
                        Text(name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color.primary)
                        
                        Text(profileManager.bio.isEmpty || profileManager.bio.count < 3 ? "I love to eat!!" : profileManager.bio)
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                            .italic()
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // 2. Stats Row
                HStack(spacing: 12) {
                    StatsCard(title: "Total Sessions", value: "\(totalSessions)", extra: "", color: .mint, icon: "star.fill")
                    StatsCard(title: "Current Streak", value: "\(currentStreak) Days", extra: "", color: .purple, icon: "flame.fill")
                    StatsCard(title: "Focus Area", value: topFocus, extra: "", color: .orange, icon: "mic.fill")
                }
                .padding(.horizontal)
                
                // 3. Activity Grid
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activity (\(Date().formatted(.dateTime.month(.wide))))")
                            .font(sizeClass == .regular ? .title3 : .headline) // Larger font for iPad
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.leading, 24)
                            .padding(.top, 20)
                        
                        MonthActivityHeatmap(dailySessions: dailySessions, selectedDateWrapper: $selectedDateWrapper)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                    
                    Divider()
                        .background(.white.opacity(0.3))
                        .padding(.vertical, 20)
                    
                    // Yearly Button - Made more prominent for iPad
                    Button {
                        showYearlyHistory = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(sizeClass == .regular ? .title : .title2)
                            Text("Yearly")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .frame(width: sizeClass == .regular ? 100 : 70)
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(LinearGradient(colors: [Color.teal, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                .shadow(color: .cyan.opacity(0.3), radius: 12, y: 6)
                
                // 4. Progress Section
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("My Progress")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        VStack(spacing: 6) {
                            HStack {
                                Text("Level 12")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.yellow)
                                Spacer()
                                Text("1,250 / 2,000 XP")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.black.opacity(0.3))
                                    Capsule()
                                        .fill(Color.yellow)
                                        .frame(width: geo.size.width * 0.62)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                    .padding(20)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.yellow)
                        .padding(.trailing, 20)
                        .shadow(color: .yellow.opacity(0.5), radius: 10)
                }
                .background(
                    LinearGradient(colors: [Color.indigo, Color.blue], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(20)
                .padding(.horizontal)
                .shadow(color: .indigo.opacity(0.3), radius: 8, y: 4)
                
                // 5. Global Growth Graph
                if !globalHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Overall Growth")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ProgressTrendGraph(
                            history: globalHistory,
                            currentScore: nil,
                            currentConfidence: nil,
                            extraDataMap: sessionNameMap
                        )
                        .padding(.bottom, 10)
                    }
                }
                
                // 6. Account Settings
                Button {
                    showSettings = true
                } label: {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundStyle(Color.primary)
                            .padding(10)
                            .background(Color(UIColor.secondarySystemFill))
                            .clipShape(Circle())
                        
                        Text("Account Settings")
                            .font(.headline)
                            .foregroundStyle(Color.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(15)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .onAppear(perform: loadStats)
        .sheet(isPresented: $showSettings) {
             SettingsSheet()
                .presentationDetents([.large, .medium], selection: $settingsDetent)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showYearlyHistory) {
            YearlyHistoryView(activityDates: Set(dailySessions.keys))
        }
        // Daily Details Sheet
        .sheet(item: $selectedDateWrapper) { wrapper in
            DailyActivityDetailView(date: wrapper.date, sessions: dailySessions[wrapper.date] ?? [])
                .presentationDetents([.medium, .fraction(0.7)])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Logic
    func loadStats() {
        if let data = UserDefaults.standard.data(forKey: "savedPracticeSessions"),
           let sessions = try? JSONDecoder().decode([PracticeSession].self, from: data) {
            
            // Count total unique "completed" events? Or just sessions designed?
            // "Total Sessions" probably means sessions practiced.
            // Loop through logs.
            
            var count = 0
            var map: [Date: [PracticeSession]] = [:]
            
            // Temporary map builder
            var nameMap: [UUID: String] = [:]
            
            for session in sessions {
                // If log exists, use it
                if !session.practiceLog.isEmpty {
                    count += session.practiceLog.count
                    for date in session.practiceLog {
                        let day = Calendar.current.startOfDay(for: date)
                        map[day, default: []].append(session)
                    }
                } else if session.recordingFileName != nil, let date = session.createdDate {
                    // Fallback for legacy data (before logging was added)
                    let day = Calendar.current.startOfDay(for: date)
                    map[day, default: []].append(session)
                    count += 1
                }
                
                // Populate Name Map for History
                for attempt in session.history {
                    nameMap[attempt.id] = session.name
                }
            }
            
            totalSessions = count
            dailySessions = map
            sessionNameMap = nameMap
            
            currentStreak = calculateStreak(dates: Set(dailySessions.keys))
            
            // Top Focus
            let allFoci = sessions.flatMap { $0.foci }
            let counts = allFoci.reduce(into: [:]) { counts, focus in
                counts[focus.title, default: 0] += 1
            }
            if let top = counts.max(by: { $0.value < $1.value }) {
                topFocus = top.key
                if topFocus == "Facial Aesthetics" { topFocus = "Facial" }
                if topFocus == "Body Language" { topFocus = "Body" }
                if topFocus == "Vocal Control" { topFocus = "Vocal" }
            } else {
                topFocus = "—"
            }
            
            // Global History (All Attempts)
            var allAttempts = sessions.flatMap { $0.history }
            
            // Load Archived History
            if let arcData = UserDefaults.standard.data(forKey: "archivedPracticeHistory"),
               let archived = try? JSONDecoder().decode([PracticeAttempt].self, from: arcData) {
                allAttempts.append(contentsOf: archived)
                
                // Add to Name Map if name is present
                for attempt in archived {
                    if let sName = attempt.sessionName {
                        nameMap[attempt.id] = sName
                    }
                }
            }
