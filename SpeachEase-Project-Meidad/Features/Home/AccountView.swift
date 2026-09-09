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
