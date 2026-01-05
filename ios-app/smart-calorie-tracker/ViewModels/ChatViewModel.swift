import Foundation
import SwiftData
import Observation

@Observable
final class ChatViewModel {
    var messages: [ChatMessage] = []
    
    // Функция для создания ответа от "ИИ" (пока заглушка)
    func generateAIResponse(for userText: String) -> String {
        let text = userText.lowercased()
        if text.contains("привет") {
            return "Привет! Я твой умный счетчик калорий. Что ты сегодня ел?"
        } else if text.contains("калори") {
            return "Я могу помочь рассчитать калории. Просто напиши название блюда."
        } else {
            return "Интересно! Я записал это. Хочешь узнать пищевую ценность?"
        }
    }
}