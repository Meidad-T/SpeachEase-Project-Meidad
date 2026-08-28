import SwiftUI
import Combine

@MainActor
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    @Published var firstName: String = "" {
        didSet { UserDefaults.standard.set(firstName, forKey: "user_firstName") }
    }
    @Published var lastName: String = "" {
        didSet { UserDefaults.standard.set(lastName, forKey: "user_lastName") }
    }
    @Published var displayName: String = "" {
        didSet { UserDefaults.standard.set(displayName, forKey: "user_displayName") }
    }
    @Published var useDisplayName: Bool = false {
        didSet { UserDefaults.standard.set(useDisplayName, forKey: "user_useDisplayName") }
    }
    @Published var favoriteColorHex: String = "#5856D6" { // Default Purple
        didSet { UserDefaults.standard.set(favoriteColorHex, forKey: "user_favoriteColor") }
    }
    @Published var isOnboardingCompleted: Bool = false {
        didSet { UserDefaults.standard.set(isOnboardingCompleted, forKey: "user_isOnboardingCompleted") }
    }
    
    @Published var bio: String = "" {
        didSet { UserDefaults.standard.set(bio, forKey: "user_bio") }
    }
    
    @Published var profileImage: UIImage?
    
    init() {
        self.firstName = UserDefaults.standard.string(forKey: "user_firstName") ?? ""
        self.lastName = UserDefaults.standard.string(forKey: "user_lastName") ?? ""
        self.displayName = UserDefaults.standard.string(forKey: "user_displayName") ?? ""
        self.useDisplayName = UserDefaults.standard.bool(forKey: "user_useDisplayName")
        self.favoriteColorHex = UserDefaults.standard.string(forKey: "user_favoriteColor") ?? "#5856D6"
        self.bio = UserDefaults.standard.string(forKey: "user_bio") ?? ""
        self.isOnboardingCompleted = UserDefaults.standard.bool(forKey: "user_isOnboardingCompleted")
        loadProfileImage()
    }
    
    var favoriteColor: Color {
        Color(hex: favoriteColorHex)
    }
    
    func saveProfile(first: String, last: String, display: String, useDisplay: Bool, color: Color, bio: String) {
        self.firstName = first
        self.lastName = last
        self.displayName = display
        self.useDisplayName = useDisplay
        self.favoriteColorHex = color.toHex() ?? "#5856D6"
        self.bio = bio
        withAnimation {
            self.isOnboardingCompleted = true
        }
    }
    
    // MARK: - Image Persistence
    
    func saveProfileImage(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            let filename = getDocumentsDirectory().appendingPathComponent("profile.jpg")
            try? data.write(to: filename)
            self.profileImage = image
        }
    }
    
    private func loadProfileImage() {
        let filename = getDocumentsDirectory().appendingPathComponent("profile.jpg")
        if let data = try? Data(contentsOf: filename) {
            self.profileImage = UIImage(data: data)
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func logout() {
        withAnimation {
             self.isOnboardingCompleted = false
             // Optional: Clear other data if needed
        }
    }
    
    func resetToDefaults() {
        // 1. Clear UserDefaults
        let keys = [
            "user_firstName",
            "user_lastName",
            "user_displayName",
            "user_useDisplayName",
            "user_favoriteColor",
            "user_bio",
            "user_isOnboardingCompleted"
        ]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        
        // 2. Delete Profile Image
        let filename = getDocumentsDirectory().appendingPathComponent("profile.jpg")
        try? FileManager.default.removeItem(at: filename)
        
        // 3. Reset State
        withAnimation {
            self.firstName = ""
            self.lastName = ""
