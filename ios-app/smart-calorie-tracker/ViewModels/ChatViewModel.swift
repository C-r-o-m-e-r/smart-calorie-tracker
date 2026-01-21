import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    
    // Database context for history and data fetching
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Send Message Logic
    func sendMessage(context: ModelContext) {
        // 1. Validate Input
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let originalUserMessage = text
        inputText = "" // Clear input field
        isLoading = true
        
        // 2. Save User Message to Local History (Display in UI)
        let userMsg = ChatMessage(text: originalUserMessage, isUser: true)
        context.insert(userMsg)
        
        // 3. Build Natural Context (The "Secret" Ingredient)
        // We construct a natural sentence describing the user's state.
        let userDataContext = gatherUserData(context: context)
        
        // 4. Construct the Final Prompt
        // We wrap the user's question with data, making it look like a clear instruction.
        let finalPrompt = """
        Current User Data:
        \(userDataContext)
        
        User Question: "\(originalUserMessage)"
        
        Instruction: Act as a professional nutritionist. Use the user's data above (weight, height, eaten calories) to give specific, short, and helpful advice.
        """
        
        print("📤 CHAT_VM: Sending enriched prompt to AI...")
        // Debug: Print to console to see what exactly is being sent
        print(finalPrompt)
        
        // 5. Send to Server
        NetworkService.shared.sendChatMessage(message: finalPrompt) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let reply):
                    print("✅ CHAT_VM: AI Response received.")
                    // Save AI Response to Local History
                    let aiMsg = ChatMessage(text: reply, isUser: false)
                    context.insert(aiMsg)
                    
                case .failure(let error):
                    print("❌ CHAT_VM: Error - \(error.localizedDescription)")
                    // Save Error Message
                    let errorMsg = ChatMessage(text: "Connection failed: \(error.localizedDescription)", isUser: false)
                    context.insert(errorMsg)
                }
                
                // Persist all changes
                try? context.save()
            }
        }
    }
    
    // MARK: - Data Gathering Helper
    private func gatherUserData(context: ModelContext) -> String {
        var infoDetails = ""
        
        // A. Fetch Profile (Weight, Height, Goal)
        let profileDescriptor = FetchDescriptor<UserProfile>()
        if let profile = try? context.fetch(profileDescriptor).first {
            infoDetails += "- Physical Stats: Weight \(Int(profile.weight))kg, Height \(Int(profile.height))cm.\n"
            infoDetails += "- Daily Goal: \(profile.dailyCalories) kcal.\n"
        } else {
            infoDetails += "- Physical Stats: Unknown (Profile not set).\n"
        }
        
        // B. Fetch Today's Meals
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let mealDescriptor = FetchDescriptor<Meal>(predicate: #Predicate { $0.date >= startOfDay })
        
        if let meals = try? context.fetch(mealDescriptor), !meals.isEmpty {
            let totalCal = meals.map(\.calories).reduce(0, +)
            // List top 5 items to save tokens, or all if few
            let mealNames = meals.map { "\($0.name) (\($0.calories)kcal)" }.joined(separator: ", ")
            
            infoDetails += "- Consumed Today: \(totalCal) kcal.\n"
            infoDetails += "- Food Log: \(mealNames)."
        } else {
            infoDetails += "- Consumed Today: 0 kcal (User hasn't eaten yet)."
        }
        
        return infoDetails
    }
}
