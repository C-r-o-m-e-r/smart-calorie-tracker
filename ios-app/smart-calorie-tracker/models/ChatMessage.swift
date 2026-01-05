import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var text: String
    var isUser: Bool
    var date: Date

    init(text: String, isUser: Bool, date: Date = .now) {
        self.id = UUID()
        self.text = text
        self.isUser = isUser
        self.date = date
    }
}
