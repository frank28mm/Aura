import SwiftUI
import AVFoundation

struct BreathingExerciseView: View {
    @State private var isAnimating = false
    @State private var breathingPhase = "准备开始"
    @State private var currentPhase = 0
    @State private var timer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var selectedSound = "无"
    
    let breathingPattern = [
        ("吸气", 4),
        ("屏住呼吸", 4),
        ("呼气", 4),
        ("屏住呼吸", 4)
    ]
    
    let soundOptions = ["无", "小雨", "森林", "海浪"]
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.teal.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // 将标题、动画和提示文本组合成一个居中块
                VStack(spacing: 40) {
                    // 标题
                    Text("呼吸之锚")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.teal)
                    
                    // 呼吸动画圆圈
                    ZStack {
                        Circle()
                            .stroke(Color.teal.opacity(0.3), lineWidth: 2)
                            .frame(width: 300, height: 300)
                        
                        Circle()
                            .fill(Color.teal.opacity(0.6))
                            .frame(width: isAnimating ? 280 : 100, height: isAnimating ? 280 : 100)
                            .animation(
                                Animation.easeInOut(duration: 4)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                    }
                    
                    // 呼吸阶段提示
                    Text(breathingPhase)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.teal)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(15)
                }
                
                Spacer()
                
                // 音效选择
                VStack(spacing: 15) {
                    Text("背景音效")
                        .font(.headline)
                        .foregroundColor(.teal)
                    
                    Picker("音效", selection: $selectedSound) {
                        ForEach(soundOptions, id: \.self) { sound in
                            Text(sound).tag(sound)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }
                
                // 控制按钮
                Button(action: {
                    if isAnimating {
                        stopBreathing()
                    } else {
                        startBreathing()
                    }
                }) {
                    Text(isAnimating ? "停止" : "开始")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 120, height: 50)
                        .background(isAnimating ? Color.red : Color.teal)
                        .cornerRadius(25)
                }
                .padding(.bottom, 30)
            }
            .padding()
        }
    }
    
    func startBreathing() {
        isAnimating = true
        currentPhase = 0
        updateBreathingPhase()
        playBackgroundSound()
        
        timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
            currentPhase = (currentPhase + 1) % breathingPattern.count
            updateBreathingPhase()
        }
    }
    
    func stopBreathing() {
        isAnimating = false
        timer?.invalidate()
        timer = nil
        breathingPhase = "准备开始"
        audioPlayer?.stop()
    }
    
    func updateBreathingPhase() {
        breathingPhase = breathingPattern[currentPhase].0
    }
    
    func playBackgroundSound() {
        guard selectedSound != "无" else { return }
        
        // 这里应该添加实际的音频文件
        // 由于这是演示，我们只是模拟音效播放
        print("播放 \(selectedSound) 音效")
    }
}

struct BreathingExerciseView_Previews: PreviewProvider {
    static var previews: some View {
        BreathingExerciseView()
    }
}