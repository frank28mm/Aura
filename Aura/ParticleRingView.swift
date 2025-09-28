import SwiftUI

private struct Particle: Identifiable {
    let id = UUID()
    var size: CGFloat
    var position: CGPoint
    var opacity: Double
}

struct ParticleRingView: View {
    // 状态变量
    @State private var particlesInitialized = false
    @State private var ringParticles: [Particle] = []
    @State private var dustParticles: [Particle] = []
    @State private var satelliteParticles: [Particle] = []
    
    // 从外部接收动画控制参数
    @Binding var scale: CGFloat
    @Binding var rotationAngle: Angle

    // 可配置属性
    let colors: [Color]
    let radius: CGFloat

    init(scale: Binding<CGFloat>, rotationAngle: Binding<Angle>, colors: [Color] = [Color.teal], radius: CGFloat = 100.0) {
        self._scale = scale
        self._rotationAngle = rotationAngle
        self.colors = colors
        self.radius = radius
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(dustParticles) { particle in
                    Circle()
                        .fill((colors.randomElement() ?? .white).opacity(0.5))
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                }

                ZStack {
                    ForEach(ringParticles) { particle in
                        Circle()
                            .fill(colors.randomElement() ?? .white)
                            .frame(width: particle.size, height: particle.size)
                            .position(particle.position)
                    }
                    
                    ForEach(satelliteParticles) { particle in
                        Circle()
                            .fill(colors.randomElement() ?? .white)
                            .frame(width: particle.size, height: particle.size)
                            .position(particle.position)
                    }
                }
                .rotationEffect(rotationAngle)
                .scaleEffect(scale)
            }
            .onAppear {
                if !particlesInitialized {
                    setupParticles(center: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2), size: geometry.size)
                    particlesInitialized = true
                }
            }
        }
    }
    
    func setupParticles(center: CGPoint, size: CGSize) {
        // 初始化“土星环”粒子
        for _ in 0..<600 {
            let angle = Double.random(in: 0..<(2 * .pi))
            let r = CGFloat.random(in: (radius * 0.9)...(radius * 1.1))
            let x = cos(angle) * r + center.x
            let y = sin(angle) * r + center.y
            let particle = Particle(size: .random(in: 1...3), position: CGPoint(x: x, y: y), opacity: .random(in: 0.2...0.7))
            ringParticles.append(particle)
        }
        
        // 初始化内部“卫星”粒子
        for _ in 0..<300 {
            let angle = Double.random(in: 0..<(2 * .pi))
            let r = CGFloat.random(in: (radius * 0.8)...(radius * 0.88))
            let x = cos(angle) * r + center.x
            let y = sin(angle) * r + center.y
            let particle = Particle(size: .random(in: 0.5...1.5), position: CGPoint(x: x, y: y), opacity: .random(in: 0.1...0.4))
            satelliteParticles.append(particle)
        }

        // 初始化外部“卫星”粒子
        for _ in 0..<300 {
            let angle = Double.random(in: 0..<(2 * .pi))
            let r = CGFloat.random(in: (radius * 1.12)...(radius * 1.2))
            let x = cos(angle) * r + center.x
            let y = sin(angle) * r + center.y
            let particle = Particle(size: .random(in: 0.5...1.5), position: CGPoint(x: x, y: y), opacity: .random(in: 0.1...0.4))
            satelliteParticles.append(particle)
        }

        // 初始化背景“星尘”
        for _ in 0..<50 {
            let x = CGFloat.random(in: 0...size.width)
            let y = CGFloat.random(in: 0...size.height)
            let particle = Particle(size: .random(in: 1...2), position: CGPoint(x: x, y: y), opacity: .random(in: 0.1...0.5))
            dustParticles.append(particle)
        }
    }
}