import SwiftUI

struct GroundingExerciseView: View {
    @State private var currentStep = 0
    @State private var userInputs: [String] = Array(repeating: "", count: 5)
    @State private var isCompleted = false
    
    let steps = [
        ("深呼吸。现在，环顾四周，说出你看到的5样东西。", 5),
        ("很好。现在，专注于你身体能感觉到的4种触感。", 4),
        ("仔细听。你能听到的3种声音是什么？", 3),
        ("你闻到了哪2种气味？", 2),
        ("最后，你能尝到的1种味道是什么？", 1)
    ]
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.1), Color.blue.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 标题
                Text("感官接地")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Spacer()
                
                if !isCompleted {
                    // 当前步骤
                    VStack { // Removed spacing
                        Text(steps[currentStep].0)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.bottom, 20) // Added padding
                        
                        // 输入框
                        VStack(spacing: 15) {
                            ForEach(0..<steps[currentStep].1, id: \.self) { index in
                                TextField("第\(index + 1)项", text: binding(for: currentStep * 5 + index))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal)
                            }
                        }
                        
                        Spacer() // Added Spacer to push content to top and bottom

                        // 下一步按钮
                        Button(action: {
                            if currentStep < steps.count - 1 {
                                currentStep += 1
                            } else {
                                isCompleted = true
                            }
                        }) {
                            Text(currentStep < steps.count - 1 ? "下一步" : "完成")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 120, height: 50)
                                .background(Color.green)
                                .cornerRadius(25)
                        }
                        .padding(.bottom, 10) // Added padding

                        // 进度指示器
                        HStack(spacing: 20) {
                            ForEach(0..<steps.count, id: \.self) { index in
                                Circle()
                                    .fill(index <= currentStep ? Color.green : Color.gray.opacity(0.3))
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .frame(height: 520)
                } else {
                    // 完成页面
                    VStack(spacing: 30) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        Text("你在这里。你很安全。一切尽在掌控。")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                        
                        Text("你已经成功完成了感官接地练习。记住这个平静的感觉。")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            // 重新开始
                            currentStep = 0
                            userInputs = Array(repeating: "", count: 5)
                            isCompleted = false
                        }) {
                            Text("重新开始")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 140, height: 50)
                                .background(Color.green)
                                .cornerRadius(25)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    func binding(for index: Int) -> Binding<String> {
        Binding<String>(
            get: {
                if index < userInputs.count {
                    return userInputs[index]
                }
                return ""
            },
            set: { newValue in
                if index < userInputs.count {
                    userInputs[index] = newValue
                }
            }
        )
    }
}

struct GroundingExerciseView_Previews: PreviewProvider {
    static var previews: some View {
        GroundingExerciseView()
    }
}