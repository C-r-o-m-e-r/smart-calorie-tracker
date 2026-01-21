import SwiftUI
import SwiftData

// Enum for Activity Level (English)
private enum ActivityLevel: String, CaseIterable, Identifiable {
    case inactive = "Sedentary (Inactive)"
    case active = "Active"

    var id: String { rawValue }

    var multiplier: Double {
        switch self {
        case .inactive: return 1.2
        case .active: return 1.55
        }
    }
}

struct ProfileView: View {
    // 1. Persistent Login State (Matches the logic in AuthView)
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    
    @Environment(\.modelContext) private var context
    
    // Fetch local user profile from SwiftData
    @Query private var profiles: [UserProfile]
    
    // Temporary state for input fields
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var activityLevel: ActivityLevel = .inactive
    
    // Get the current profile (first in the list)
    var userProfile: UserProfile? {
        profiles.first
    }

    // Calculate calories based on inputs
    private var calculatedDailyCalories: Int {
        let w = Double(weight) ?? 0.0
        let h = Double(height) ?? 0.0

        guard w > 0, h > 0 else { return 0 }

        // Simple BMR formula example (Mifflin-St Jeor approx)
        let base = 10 * w + 6.25 * h
        let total = base * activityLevel.multiplier
        return Int(total.rounded())
    }

    var body: some View {
        // 2. CHECK IF LOGGED IN
        if isLoggedIn {
            NavigationStack {
                Form {
                    // --- SECTION 1: BODY METRICS ---
                    Section(header: Text("Body Metrics")) {
                        HStack {
                            Text("Weight (kg)")
                            Spacer()
                            TextField("0", text: $weight)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Height (cm)")
                            Spacer()
                            TextField("0", text: $height)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    // --- SECTION 2: ACTIVITY ---
                    Section(header: Text("Activity Level")) {
                        Picker("Lifestyle", selection: $activityLevel) {
                            ForEach(ActivityLevel.allCases) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }
                        .pickerStyle(.menu) // Changed to menu for better text visibility
                    }
                    
                    // --- SECTION 3: GOALS ---
                    Section(header: Text("Goals")) {
                        HStack {
                            Text("Daily Calorie Target")
                            Spacer()
                            Text("\(calculatedDailyCalories) kcal")
                                .foregroundColor(.blue)
                                .bold()
                        }
                    }
                    
                    // --- SECTION 4: ACTIONS ---
                    Section {
                        Button("Save Changes") {
                            saveProfile()
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.blue)
                    }
                    
                    Section {
                        Button("Log Out") {
                            performLogout()
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.red)
                    }
                }
                .navigationTitle("Profile")
                .onAppear {
                    loadData()
                }
            }
        } else {
            // 3. SHOW AUTH VIEW IF NOT LOGGED IN
            AuthView()
        }
    }

    // Load data from SwiftData into TextFields
    private func loadData() {
        if let profile = userProfile {
            weight = String(profile.weight)
            height = String(profile.height)
            // Try to match the stored string to the Enum, default to inactive
            activityLevel = ActivityLevel(rawValue: profile.activityLevel) ?? .inactive
        }
    }

    // Save data to SwiftData
    private func saveProfile() {
        let w = Double(weight) ?? 0.0
        let h = Double(height) ?? 0.0
        let g = calculatedDailyCalories
        let activity = activityLevel.rawValue
        
        if let profile = userProfile {
            // Update existing
            profile.weight = w
            profile.height = h
            profile.dailyCalories = g
            profile.activityLevel = activity
        } else {
            // Create new if it doesn't exist
            let newProfile = UserProfile(weight: w, height: h, dailyCalories: g, activityLevel: activity)
            context.insert(newProfile)
        }
        
        try? context.save()
        print("✅ Profile saved locally.")
    }
    
    // Logout Logic
    private func performLogout() {
        // 1. Clear Token
        NetworkService.shared.authToken = nil
        
        // 2. Set State to False (Triggers AuthView)
        isLoggedIn = false
        
        print("👋 User logged out.")
    }
}
