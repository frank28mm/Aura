import SwiftUI
import AVFoundation

struct BreathingExerciseView: View {
    // 动画状态
    @State private var circleScale: CGFloat = 1.0
    @State private var isAnimating = false
    
    // 呼吸阶段
    @State private var breathingPhase = "准备开始"
    @State private var rotationAngle: Angle = .zero // 旋转角度
    
    // 音效
    @State private var audioPlayer: AVAudioPlayer?
    @State private var selectedSound = "无"
    let soundOptions = ["无", "小雨", "森林", "海浪"]

    // 呼吸模式: (阶段名称, 持续时间, 目标缩放比例)
    let breathingPattern = [
        (name: "吸气", duration: 4.0, scale: 1.4),
        (name: "屏住呼吸", duration: 4.0, scale: 1.4),
        (name: "呼气", duration: 4.0, scale: 1.0),
        (name: "屏住呼吸", duration: 4.0, scale: 1.0)
    ]

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
                
                VStack(spacing: 40) {
                    Text("呼吸之锚")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.teal)
                    
                    // 使用可重用的粒子视图
                    ParticleRingView(scale: $circleScale, rotationAngle: $rotationAngle)
                        .frame(width: 300, height: 300)
                    
                    Text(breathingPhase)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.teal)
                }
                
                Spacer()
                
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
                
                Button(action: {
                    isAnimating.toggle()
                    if isAnimating {
                        startBreathingCycle()
                    } else {
                        stopBreathing()
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
        .onAppear {
            startIdleAnimation()
        }
        .onDisappear(perform: stopBreathing)
        .onChange(of: selectedSound) { _ in
            playBackgroundSound()
        }
    }
    
    func startIdleAnimation() {
        withAnimation(Animation.linear(duration: 60).repeatForever(autoreverses: false)) {
            rotationAngle = .degrees(360)
        }
    }
    
    func startBreathingCycle() {
        runPhase(at: 0)
    }

    func runPhase(at index: Int) {
        guard isAnimating, index < breathingPattern.count else {
            if isAnimating { runPhase(at: 0) } // 循环
            return
        }

        let phase = breathingPattern[index]
        breathingPhase = phase.name

        withAnimation(.easeInOut(duration: phase.duration)) {
            circleScale = phase.scale
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + phase.duration) {
            runPhase(at: index + 1)
        }
    }
    
    func stopBreathing() {
        isAnimating = false
        breathingPhase = "准备开始"
        
        withAnimation(.easeInOut(duration: 1.0)) {
            circleScale = 1.0
        }
    }
    
    func playBackgroundSound() {
        // 停止当前可能在播放的音效
        audioPlayer?.stop()

        // 如果选择“无”，则不播放任何音效
        guard selectedSound != "无" else { return }

        var soundName: String?
        var soundExtension: String?

        switch selectedSound {
        case "小雨":
            soundName = "rain"
            soundExtension = "mp3"
        case "森林":
            soundName = "forest"
            soundExtension = "MP3"
        case "海浪":
            soundName = "waves"
            soundExtension = "wav"
        default:
            break
        }

        if let soundName = soundName, let soundExtension = soundExtension,
           let url = Bundle.main.url(forResource: soundName, withExtension: soundExtension) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1 // 无限循环
                audioPlayer?.play()
            } catch {
                print("无法加载音效文件: \(error.localizedDescription)")
            }
        }
    }
}

struct BreathingExerciseView_Previews: PreviewProvider {
    static var previews: some View {
        BreathingExerciseView()
    }
}