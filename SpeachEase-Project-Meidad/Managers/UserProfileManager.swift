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
            self.displayName = ""
            self.useDisplayName = false
            self.favoriteColorHex = "#5856D6"
            self.bio = ""
            self.profileImage = nil
            self.isOnboardingCompleted = false
        }
    }
}

// MARK: - Color Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String? {
        // Simple conversion for basic colors, relying on UIColor bridging
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if a != 1.0 {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
    
    var complementary: Color {
        let uiColor = UIColor(self)
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        if uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            let newHue = (h + 0.5).truncatingRemainder(dividingBy: 1.0)
            return Color(hue: newHue, saturation: s, brightness: b, opacity: a)
        }
        return self // Fallback if conversion fails
    }
}
