import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    ExploreView()
                }
                .tabItem {
                    Label("Explore", systemImage: "magnifyingglass")
                }
                
                NavigationStack {
                    PracticeView()
                }
                .tabItem {
                    Label("Practice", systemImage: "gamecontroller.fill")
                }
                
                NavigationStack {
                    AccountView()
                }
                .tabItem {
                    Label("Account", systemImage: "person.circle.fill")
                }
                
                NavigationStack {
                    MicTestView()
                }
                .tabItem {
                    Label("Mic Test", systemImage: "mic.fill")
                }
                
                NavigationStack {
                    CameraTestView()
                }
