import SwiftUI

// 呼吸模式枚举
enum BreathingPattern: String, CaseIterable {
    case box = "盒子呼吸法"
    case fourSevenEight = "4-7-8呼吸法"
    case coherent = "连贯呼吸法"
    
    var description: String {
        switch self {
        case .box:
            return "吸气4秒 → 屏息4秒 → 呼气4秒 → 屏息4秒"
        case .fourSevenEight:
            return "吸气4秒 → 屏息7秒 → 呼气8秒"
        case .coherent:
            return "吸气5秒 → 呼气5秒"
        }
    }
    
    var phases: [(String, Double)] {
        switch self {
        case .box:
            return [("吸气", 4), ("屏息", 4), ("呼气", 4), ("屏息", 4)]
        case .fourSevenEight:
            return [("吸气", 4), ("屏息", 7), ("呼气", 8)]
        case .coherent:
            return [("吸气", 5), ("呼气", 5)]
        }
    }
}

// AI助手情绪类型枚举
enum EmotionType: String, CaseIterable {
    case anxiety = "焦虑"
    case stress = "压力"
    case sadness = "悲伤"
    case anger = "愤怒"
    case loneliness = "孤独"
    case confusion = "困惑"
    case gratitude = "感恩"
    case happiness = "快乐"
    case neutral = "中性"
    
    var emoji: String {
        switch self {
        case .anxiety: return "😰"
        case .stress: return "😣"
        case .sadness: return "😢"
        case .anger: return "😠"
        case .loneliness: return "😔"
        case .confusion: return "🤔"
        case .gratitude: return "🙏"
        case .happiness: return "😊"
        case .neutral: return "😐"
        }
    }
    
    var color: Color {
        switch self {
        case .anxiety, .stress, .sadness, .loneliness:
            return .blue
        case .anger:
            return .red
        case .confusion:
            return .orange
        case .gratitude, .happiness:
            return .green
        case .neutral:
            return .gray
        }
    }
    
    var description: String {
        switch self {
        case .anxiety:
            return "感到担心、紧张或不安"
        case .stress:
            return "感到压力重重或不堪重负"
        case .sadness:
            return "感到悲伤、沮丧或失落"
        case .anger:
            return "感到愤怒、烦躁或不满"
        case .loneliness:
            return "感到孤独、被孤立或缺乏连接"
        case .confusion:
            return "感到困惑、迷茫或不确定"
        case .gratitude:
            return "感到感恩、感激或满足"
        case .happiness:
            return "感到快乐、开心或积极"
        case .neutral:
            return "感觉平静或中性"
        }
    }
}

// 音效管理器
class SoundManager {
    static let shared = SoundManager()
    private init() {}
    
    enum SoundType: String, CaseIterable {
        case rain = "小雨"
        case forest = "森林"
        case ocean = "海浪"
        case silence = "无"
        
        var filename: String? {
            switch self {
            case .rain: return "rain.mp3"
            case .forest: return "forest.mp3"
            case .ocean: return "ocean.mp3"
            case .silence: return nil
            }
        }
    }
}

// 扩展颜色
extension Color {
    static let calmTeal = Color(red: 0.2, green: 0.6, blue: 0.7)
    static let calmGreen = Color(red: 0.3, green: 0.7, blue: 0.4)
    static let calmBlue = Color(red: 0.4, green: 0.5, blue: 0.8)
}

// 动画效果
struct BreathingAnimation: View {
    @Binding var isAnimating: Bool
    let phase: String
    let color: Color
    
    var body: some View {
        ZStack {
            // 外圈
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 3)
                .frame(width: 320, height: 320)
            
            // 中圈
            Circle()
                .stroke(color.opacity(0.5), lineWidth: 2)
                .frame(width: isAnimating ? 280 : 160, height: isAnimating ? 280 : 160)
                .animation(
                    Animation.easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            // 内圈
            Circle()
                .fill(color.opacity(0.7))
                .frame(width: isAnimating ? 240 : 120, height: isAnimating ? 240 : 120)
                .animation(
                    Animation.easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .overlay(
                    Text(phase)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                )
        }
    }
}

// 自定义按钮样式
struct CalmButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let isActive: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: 120, height: 50)
            .background(isActive ? Color.red : backgroundColor)
            .cornerRadius(25)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}