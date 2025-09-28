import SwiftUI

@main
struct AuraApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            BreathingExerciseView()
                .tabItem {
                    Label("呼吸之锚", systemImage: "infinity")
                }
                .tag(0)
            
            GroundingExerciseView()
                .tabItem {
                    Label("感官接地", systemImage: "leaf.fill")
                }
                .tag(1)
            
            AIChatView()
                .tabItem {
                    Label("回声树洞", systemImage: "waveform")
                }
                .tag(2)
        }
        .accentColor(.teal)
    }
}
