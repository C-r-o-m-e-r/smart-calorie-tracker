import SwiftData

@Model
final class ChatMessage {
    var text: String
    var isUser: Bool
    var date: Date

    init(text: String, isUser: Bool, date: Date = .now) {
        self.text = text
        self.isUser = isUser
        self.date = date
    }
}
