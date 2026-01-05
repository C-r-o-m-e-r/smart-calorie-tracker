import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var context
    // Автоматически подтягиваем сообщения из SwiftData
    @Query(sort: \ChatMessage.date, order: .forward) private var allMessages: [ChatMessage]
    
    @State private var viewModel = ChatViewModel()
    @State private var inputText: String = ""

    init() {}

    var body: some View {
        NavigationStack {
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(allMessages) { message in
                                ChatBubble(message: message)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: allMessages.count) {
                        // Автопрокрутка вниз при новом сообщении
                        withAnimation {
                            proxy.scrollTo(allMessages.last?.id, anchor: .bottom)
                        }
                    }
                }

                // Панель ввода
                HStack(spacing: 12) {
                    TextField("Напишите сообщение...", text: $inputText)
                        .padding(10)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    .disabled(inputText.isEmpty)
                }
                .padding()
            }
            .navigationTitle("AI Помощник")
        }
    }

    private func sendMessage() {
        let text = inputText
        inputText = ""
        
        // 1. Сохраняем сообщение пользователя
        let userMsg = ChatMessage(text: text, isUser: true)
        context.insert(userMsg)
        
        // 2. Имитируем задержку ответа бота
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let aiText = viewModel.generateAIResponse(for: text)
            let aiMsg = ChatMessage(text: aiText, isUser: false)
            context.insert(aiMsg)
        }
    }
}

// Вспомогательный View для "пузырька" сообщения
struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            Text(message.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(message.isUser ? Color.blue : Color(.systemGray5))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(20)
                .shadow(radius: 1)
            
            if !message.isUser { Spacer() }
        }
    }
}
