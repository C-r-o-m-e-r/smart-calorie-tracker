import SwiftUI
import SwiftData

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @Environment(\.modelContext) private var context
    
    // Читаємо повідомлення з бази даних, сортуємо за часом (найстаріші зверху)
    @Query(sort: \ChatMessage.date, order: .forward) private var allMessages: [ChatMessage]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // --- СПИСОК ПОВІДОМЛЕНЬ ---
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Якщо повідомлень немає - показуємо привітання
                            if allMessages.isEmpty {
                                VStack(spacing: 20) {
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray.opacity(0.3))
                                    Text("Chat History is Empty.\nSay Hello!")
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.gray)
                                }
                                .padding(.top, 50)
                            }
                            
                            // Виводимо всі повідомлення
                            ForEach(allMessages) { msg in
                                ChatBubble(message: msg)
                                    .id(msg.id) // ID для автоскролу
                            }
                            
                            // Індикатор, коли AI думає
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .padding(.trailing, 5)
                                    Text("AI is typing...")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                                .padding(.leading)
                                .id("loader")
                            }
                        }
                        .padding()
                    }
                    // Автоскрол вниз при новому повідомленні
                    .onChange(of: allMessages.count) {
                        if let lastId = allMessages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                    // Автоскрол при появі лоадера
                    .onChange(of: viewModel.isLoading) {
                        if viewModel.isLoading {
                            withAnimation {
                                proxy.scrollTo("loader", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // --- ПОЛЕ ВВОДУ ---
                HStack(spacing: 10) {
                    TextField("Type your message...", text: $viewModel.inputText)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(20)
                        .disabled(viewModel.isLoading)
                        .submitLabel(.send)
                        .onSubmit {
                            if !viewModel.inputText.isEmpty {
                                viewModel.sendMessage(context: context)
                            }
                        }
                    
                    // Кнопка відправки
                    Button {
                        viewModel.sendMessage(context: context)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(viewModel.inputText.isEmpty || viewModel.isLoading ? .gray : .blue)
                    }
                    .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, y: -5)
            }
            .navigationTitle("AI Chat")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Передаємо базу даних у ViewModel при запуску
                viewModel.setContext(context)
            }
        }
    }
}

// --- ДИЗАЙН ПОВІДОМЛЕННЯ ---
struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            // Якщо повідомлення від юзера - зсуваємо вправо
            if message.isUser { Spacer() }
            
            Text(message.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(message.isUser ? Color.blue : Color(.secondarySystemBackground))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(18)
                .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)
            
            // Якщо повідомлення від AI - зсуваємо вліво
            if !message.isUser { Spacer() }
        }
    }
}
