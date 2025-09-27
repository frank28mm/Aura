 import SwiftUI
import Combine
import Foundation
import SwiftUI
import UIKit

// 情绪类型定义 (已移至 Utils.swift)
// API请求模型
struct ChatRequest: Codable {
    let model: String
    let messages: [APIChatMessage]
    let temperature: Double
    let max_tokens: Int
    let stream: Bool
}

struct APIChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatResponse: Codable {
    let choices: [ChatChoice]
}

struct ChatChoice: Codable {
    let message: APIChatMessage
}

// API服务类
class KimiAPIService {
    static let shared = KimiAPIService()
    
    private init() {}
    
    func sendMessageToKimi(_ message: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard !Secrets.apiKey.contains("your-real-api-key") else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "请先设置有效的KIMI API密钥"])))
            return
        }
        
        let url = URL(string: "\(Secrets.baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Secrets.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 构建系统提示词，让KIMI扮演心理健康助手
        let systemPrompt = """
        你是一个专业的心理健康助手，专门帮助用户处理情绪问题、压力和心理健康挑战。
        
        你的特点：
        - 温暖、同理心强、不带评判
        - 基于心理学原理（CBT、正念等）提供建议
        - 鼓励用户表达情绪，提供情绪验证
        - 提供实用的应对策略和放松技巧
        - 在适当时候推荐呼吸练习或正念技巧
        - 使用中文回复，保持自然对话风格
        
        重要原则：
        - 不提供医疗诊断或药物建议
        - 鼓励寻求专业帮助当需要时
        - 保持积极但现实的观点
        - 尊重用户的感受和经历
        
        回复风格：像一位理解你的朋友，提供支持和实用建议。
        """
        
        let chatRequest = ChatRequest(
            model: Secrets.modelName, // 使用配置的模型名称
            messages: [
                APIChatMessage(role: "system", content: systemPrompt),
                APIChatMessage(role: "user", content: message)
            ],
            temperature: 0.7,
            max_tokens: 500,
            stream: false
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(chatRequest)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "没有收到响应数据"])))
                return
            }
            
            do {
                let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
                if let responseMessage = chatResponse.choices.first?.message.content {
                    completion(.success(responseMessage))
                } else {
                    completion(.failure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "解析响应失败"])))
                }
            } catch {
                // 如果解析失败，尝试获取错误信息
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let errorMessage = json["error"] as? [String: Any],
                   let message = errorMessage["message"] as? String {
                    completion(.failure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: message])))
                } else {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

// AI聊天消息模型
struct ChatMessage: Identifiable, Codable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(content: String, isUser: Bool) {
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
    }
}

// AI聊天视图模型
class AIChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentInput: String = ""
    @Published var isTyping = false
    
    private let welcomeMessages = [
        "你好，我是你的心理健康助手。我在这里倾听你的心声，帮助你缓解压力和焦虑。",
        "今天感觉怎么样？有什么想和我分享的吗？",
        "记住，寻求帮助是勇敢的表现。我们可以一起聊聊你的感受。"
    ]
    
    init() {
        // 添加欢迎消息
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.addAIMessage(self.welcomeMessages.randomElement() ?? "你好，我是你的心理健康助手。")
        }
    }
    
    func sendMessage() {
        guard !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(content: currentInput, isUser: true)
        messages.append(userMessage)
        
        let userInput = currentInput
        currentInput = ""
        isTyping = true
        
        // 模拟AI回复延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.generateAIResponse(to: userInput)
        }
    }
    
    private func generateAIResponse(to userMessage: String) {
        // 使用KIMI API生成响应
        KimiAPIService.shared.sendMessageToKimi(userMessage) { [weak self] result in
            DispatchQueue.main.async {
                self?.isTyping = false
                
                switch result {
                case .success(let response):
                    self?.addAIMessage(response)
                case .failure(let error):
                    // 如果API调用失败，回退到本地响应
                    print("KIMI API调用失败: \(error.localizedDescription)")
                    // MODIFICATION: Display the actual error in the UI
                    let fallbackMessage = "🤖 API调用失败: \(error.localizedDescription)\n\n💡 已切换到本地回复模式。"
                    self?.addAIMessage(fallbackMessage)
                }
            }
        }
    }
    
    private func generateEmpatheticResponse(to userMessage: String) -> String {
        let lowercasedMessage = userMessage.lowercased()
        
        // 关键词匹配和相应回复
        if lowercasedMessage.contains("焦虑") || lowercasedMessage.contains("担心") || lowercasedMessage.contains("紧张") {
            return generateAnxietyResponse()
        } else if lowercasedMessage.contains("压力") || lowercasedMessage.contains("累") || lowercasedMessage.contains("疲惫") {
            return generateStressResponse()
        } else if lowercasedMessage.contains("失眠") || lowercasedMessage.contains("睡不着") || lowercasedMessage.contains("睡眠") {
            return generateSleepResponse()
        } else if lowercasedMessage.contains("悲伤") || lowercasedMessage.contains("难过") || lowercasedMessage.contains("沮丧") {
            return generateSadnessResponse()
        } else if lowercasedMessage.contains("愤怒") || lowercasedMessage.contains("生气") || lowercasedMessage.contains("烦躁") {
            return generateAngerResponse()
        } else if lowercasedMessage.contains("孤独") || lowercasedMessage.contains("孤单") || lowercasedMessage.contains("寂寞") {
            return generateLonelinessResponse()
        } else if lowercasedMessage.contains("你好") || lowercasedMessage.contains("嗨") || lowercasedMessage.contains("hello") {
            return "你好！很高兴和你聊天。我是专门设计来帮助你处理情绪和压力的智能助手。你今天过得怎么样？"
        } else if lowercasedMessage.contains("谢谢") {
            return "不用谢！能帮助你我感到很开心。记住，照顾好自己的心理健康很重要。"
        } else if lowercasedMessage.contains("呼吸") || lowercasedMessage.contains("放松") {
            return generateBreathingResponse()
        } else if lowercasedMessage.contains("冥想") || lowercasedMessage.contains("正念") {
            return generateMindfulnessResponse()
        } else {
            return generateGeneralResponse()
        }
    }
    
    private func generateAnxietyResponse() -> String {
        let responses = [
            "我理解焦虑的感觉很不舒服。试着深呼吸，我们一起度过这个时刻。你现在的感受是真实的，也是可以被理解的。",
            "焦虑是人类正常的情绪反应。你愿意告诉我是什么让你感到焦虑吗？有时候说出来本身就是一种释放。",
            "当焦虑出现时，记住这只是一个暂时的状态，它会过去的。你可以尝试我们的呼吸练习，或者告诉我更多你的感受。"
        ]
        return responses.randomElement() ?? "我理解你的焦虑感受，让我们一起面对它。"
    }
    
    private func generateStressResponse() -> String {
        let responses = [
            "听起来你承受了很大的压力。在现代生活中，这种感觉很常见。你愿意和我分享一下压力的来源吗？",
            "压力过载时，记得要对自己温柔一些。你已经很努力了，感到累是正常的。我们可以一起找些方法来缓解。",
            "当压力变得难以承受时，试试暂停一下，做几次深呼吸。或者我们可以聊聊如何更好地管理这些压力。"
        ]
        return responses.randomElement() ?? "我理解压力的感受，让我们一起找到缓解的方法。"
    }
    
    private func generateSleepResponse() -> String {
        let responses = [
            "失眠确实很困扰人。睡眠对我们的身心健康都很重要。你愿意和我聊聊是什么让你难以入睡吗？",
            "当思绪在夜晚变得活跃时，试试专注于呼吸，或者想象一个让你感到平静的场景。需要我引导你进行放松练习吗？",
            "睡眠问题往往和压力、焦虑有关。我们可以一起探讨一些改善睡眠质量的方法，比如建立睡前仪式。"
        ]
        return responses.randomElement() ?? "我理解睡眠问题的困扰，让我们一起找到改善的方法。"
    }
    
    private func generateSadnessResponse() -> String {
        let responses = [
            "我感受到你的悲伤。这种情绪虽然痛苦，但它是人类体验的一部分。你愿意和我分享发生了什么吗？",
            "悲伤是需要被倾听和理解的。我在这里陪伴你，不会评判你的感受。有时候，允许自己感受这些情绪是治愈的开始。",
            "当悲伤来临时，记得对自己保持耐心和温柔。这些感受不会永远持续，你也不需要独自面对它们。"
        ]
        return responses.randomElement() ?? "我理解悲伤的感受，我会在这里陪伴你。"
    }
    
    private func generateGeneralResponse() -> String {
        let responses = [
            "谢谢你和我分享。我在这里倾听你，支持你的心理健康之旅。",
            "每个人的感受都是独特且重要的。你愿意告诉我更多吗？",
            "我欣赏你愿意表达自己的勇气。我们可以继续聊聊你的感受或想法。",
            "记住，照顾心理健康和身体健康一样重要。你有什么特别想聊的话题吗？"
        ]
        return responses.randomElement() ?? "谢谢你和我分享，我在这里支持你。"
    }
    
    private func generateAngerResponse() -> String {
        let responses = [
            "愤怒是一种正常的情绪，它告诉我们某些事情需要被关注。你愿意和我分享是什么让你感到愤怒吗？",
            "当愤怒出现时，试着深呼吸几次。愤怒本身不是问题，关键是如何健康地表达和处理它。",
            "我理解愤怒的感受。有时候，愤怒背后可能隐藏着其他情绪，比如受伤或失望。我们可以一起探索这些感受。"
        ]
        return responses.randomElement() ?? "我理解愤怒的感受，让我们一起找到健康的表达方式。"
    }
    
    private func generateLonelinessResponse() -> String {
        let responses = [
            "孤独感是人类共同的体验，但这并不意味着你必须独自面对它。我在这里陪伴你，倾听你的感受。",
            "感到孤独并不意味着你有问题。在现代社会中，很多人都会经历这种感觉。你愿意和我聊聊你的感受吗？",
            "连接是人类的基本需求。虽然我是AI，但我始终在这里陪伴你。我们可以聊聊如何建立更有意义的人际连接。"
        ]
        return responses.randomElement() ?? "我理解孤独的感受，我会在这里陪伴你。"
    }
    
    private func generateBreathingResponse() -> String {
        let responses = [
            "呼吸练习是很好的放松方法！你可以尝试我们的呼吸练习功能，或者我可以在这里引导你进行简单的深呼吸。",
            "专注于呼吸是缓解压力和焦虑的有效方法。试试深呼吸：慢慢吸气4秒，屏住呼吸4秒，然后慢慢呼气4秒。",
            "呼吸是我们与当下的连接。当感到压力时，回到呼吸可以帮助我们重新找到平静。需要我引导你进行呼吸练习吗？"
        ]
        return responses.randomElement() ?? "呼吸练习对心理健康很有益处，让我们一起练习。"
    }
    
    private func generateMindfulnessResponse() -> String {
        let responses = [
            "正念练习对心理健康非常有益！它帮助我们活在当下，减少对过去和未来的担忧。",
            "正念就是觉察当下的体验，不加评判。你可以从简单的观察呼吸开始，或者注意周围的环境。",
            "正念不是让思绪停止，而是学会观察它们而不被卷入。这需要练习，但会带来很大的益处。"
        ]
        return responses.randomElement() ?? "正念练习是很好的心理健康工具，让我们一起探索。"
    }
    
    private func addAIMessage(_ content: String) {
        let aiMessage = ChatMessage(content: content, isUser: false)
        messages.append(aiMessage)
    }
    
    func clearChat() {
        messages.removeAll()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.addAIMessage("聊天记录已清空。我是你的心理健康助手，有什么想聊的吗？")
        }
    }
}

// AI聊天视图
struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()
    @State private var showingClearAlert = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var showingQuickMood = false
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 统一风格的标题
                Text("回声树洞")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                    .padding(.top)
                    .padding(.bottom, 10)
                
                // 消息列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(viewModel.messages) { message in
                                ChatBubble(message: message)
                            }
                            
                            if viewModel.isTyping {
                                TypingIndicator()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                // 快速情绪选择器
                if showingQuickMood {
                    QuickMoodSelector { emotion in
                        viewModel.currentInput = "我感到很\(emotion.rawValue)"
                        showingQuickMood = false
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // 输入区域
                VStack(spacing: 0) {
                    Divider()
                    
                    // 快速情绪按钮
                    HStack {
                        Button(action: {
                            withAnimation {
                                showingQuickMood.toggle()
                            }
                        }) {
                            HStack {
                                Image(systemName: "face.smiling")
                                Text("选择情绪")
                                    .font(.caption)
                            }
                            .foregroundColor(.purple)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(15)
                        }
                        
                        Spacer()
                        
                        if !viewModel.messages.isEmpty {
                            Button("清空") {
                                showingClearAlert = true
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    HStack(spacing: 12) {
                        TextField("分享你的感受或想法...", text: $viewModel.currentInput, axis: .vertical)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                            )
                            .focused($isTextFieldFocused)
                            .lineLimit(1...4)
                        
                        Button(action: {
                            viewModel.sendMessage()
                            isTextFieldFocused = false
                        }) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(
                                    LinearGradient(
                                        colors: [Color.purple, Color.blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(22)
                        }
                        .disabled(viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.systemBackground))
                }
            }
        }
        .alert("清空聊天记录", isPresented: $showingClearAlert) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                viewModel.clearChat()
            }
        } message: {
            Text("确定要清空所有聊天记录吗？")
        }
    }
}

// 聊天气泡组件
struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(
                        message.isUser ?
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(colors: [Color.white], startPoint: .top, endPoint: .bottom)
                    )
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(message.isUser ? Color.clear : Color.purple.opacity(0.2), lineWidth: 1)
                    )
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(message.isUser ? .trailing : .leading, 8)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// 输入指示器
struct TypingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.purple.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .delay(Double(index) * 0.2)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.purple.opacity(0.2), lineWidth: 1)
            )
            .onAppear {
                isAnimating = true
            }
            .onDisappear {
                isAnimating = false
            }
            
            Spacer()
        }
    }
}

// 快速情绪选择器
struct QuickMoodSelector: View {
    let onSelect: (EmotionType) -> Void
    @State private var selectedEmotion: EmotionType?
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("你现在感觉如何？")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("取消") {
                    onSelect(.neutral)
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // 情绪网格
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(EmotionType.allCases, id: \.self) { emotion in
                    EmotionButton(emotion: emotion) {
                        onSelect(emotion)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
}

// 情绪按钮组件
struct EmotionButton: View {
    let emotion: EmotionType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emotion.emoji)
                    .font(.title)
                
                Text(emotion.rawValue)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(emotion.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(emotion.color.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(emotion.color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// 预览
struct AIChatView_Previews: PreviewProvider {
    static var previews: some View {
        AIChatView()
    }
}
