import SwiftUI
import AVFoundation

// 定义单个粒子的数据结构
private struct Particle: Identifiable {
    let id = UUID()
    var size: CGFloat
    var position: CGPoint
    var opacity: Double
}

struct BreathingExerciseView: View {
    // 动画状态
    @State private var circleScale: CGFloat = 1.0
    @State private var isAnimating = false
    
    // 粒子状态
    @State private var ringParticles: [Particle] = []
    @State private var dustParticles: [Particle] = []
    
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
        (name: "呼气", duration: 5.0, scale: 1.0),
        (name: "屏住呼吸", duration: 3.0, scale: 1.0)
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
                    
                    // 粒子动画区域
                    ZStack {
                        // 背景里的“星尘”
                        ForEach(dustParticles) { particle in
                            Circle()
                                .fill(Color.white.opacity(particle.opacity))
                                .frame(width: particle.size, height: particle.size)
                                .position(particle.position)
                                .animation(isAnimating ? Animation.easeInOut(duration: Double.random(in: 2...4)).repeatForever() : .default, value: isAnimating)
                        }

                        // 构成“土星环”的粒子
                        ZStack {
                            ForEach(ringParticles) { particle in
                                Circle()
                                    .fill(Color.teal.opacity(particle.opacity))
                                    .frame(width: particle.size, height: particle.size)
                                    .position(particle.position)
                            }
                        }
                        .rotationEffect(rotationAngle) // 应用旋转效果
                        // 模糊效果已移除
                        .scaleEffect(circleScale) // 整体缩放以同步呼吸
                        
                    }
                    .frame(width: 300, height: 300)
                    
                    Text(breathingPhase)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.teal)
                        // 白色背景已移除
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
        .onAppear(perform: setupParticles)
        .onDisappear(perform: stopBreathing)
    }
    
    func setupParticles() {
        guard ringParticles.isEmpty else { return } // 防止重复生成
        
        // 初始化“土星环”粒子
        for _ in 0..<600 { // 增加粒子数量
            let angle = Double.random(in: 0..<(2 * .pi))
            let radius = CGFloat.random(in: 90...110)
            let x = cos(angle) * radius + 150
            let y = sin(angle) * radius + 150
            let particle = Particle(size: .random(in: 1...3), position: CGPoint(x: x, y: y), opacity: .random(in: 0.2...0.7)) // 减小粒子大小
            ringParticles.append(particle)
        }
        
        // 初始化背景“星尘”
        for _ in 0..<50 {
            let x = CGFloat.random(in: 0...300)
            let y = CGFloat.random(in: 0...300)
            let particle = Particle(size: .random(in: 1...2), position: CGPoint(x: x, y: y), opacity: .random(in: 0.1...0.5))
            dustParticles.append(particle)
        }
    }
    
    func startBreathingCycle() {
        playBackgroundSound()
        runPhase(at: 0)

        // 开始旋转动画
        withAnimation(Animation.linear(duration: 30).repeatForever(autoreverses: false)) {
            rotationAngle = .degrees(-360)
        }
        
        // 启动星尘闪烁
        for i in 0..<dustParticles.count {
            withAnimation(Animation.easeInOut(duration: Double.random(in: 2...5)).repeatForever()) {
                dustParticles[i].opacity = .random(in: 0.1...0.5)
            }
        }
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
        audioPlayer?.stop()
        
        withAnimation(.easeInOut(duration: 1.0)) {
            circleScale = 1.0
            rotationAngle = .zero // 重置旋转
        }
    }
    
    func playBackgroundSound() {
        guard selectedSound != "无" else { return }
        print("播放 \(selectedSound) 音效")
    }
}

struct BreathingExerciseView_Previews: PreviewProvider {
    static var previews: some View {
        BreathingExerciseView()
    }
}