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
