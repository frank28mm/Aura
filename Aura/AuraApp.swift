import SwiftUI

import SwiftUI
import AVFoundation

@main
struct AuraApp: App {
    
    init() {
        // 配置音频会话以支持后台播放
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            print("Audio session configured for background playback.")
        } catch {
            print("Failed to set up audio session for background playback: \(error.localizedDescription)")
        }
    }
    
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
