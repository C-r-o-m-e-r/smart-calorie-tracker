import SwiftUI
import SwiftData

struct AddMealView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // input fields
    @State private var name: String = ""
    @State private var caloriesText: String = ""
    @State private var proteinText: String = ""
    @State private var fatsText: String = ""
    @State private var carbsText: String = ""
    @State private var weightText: String = ""
    
    // camera and ai state
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    
    // mock service for manual search fallback
    private let mockService = MockAPIService()
    @State private var suggestions: [FoodSuggestion] = []

    var body: some View {
        NavigationStack {
            ZStack {
                // main form content
                Form {
                    // section 1: food photo
                    Section {
                        HStack {
                            Spacer()
                            Button(action: { showCamera = true }) {
                                ZStack {
                                    if let image = selectedImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                                            .shadow(radius: 5)
                                    } else {
                                        Circle()
                                            .fill(Color(.systemGray6))
                                            .frame(width: 120, height: 120)
                                            .overlay(
                                                VStack {
                                                    Image(systemName: "camera.fill")
                                                        .font(.largeTitle)
                                                        .foregroundColor(.blue)
                                                    Text("Take photo")
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                }
                                            )
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }

                    // section 2: name and search
                    Section(header: Text("Meal details")) {
                        TextField("e.g. Chicken Soup", text: $name)
                            .font(.headline)
                            .onChange(of: name) { oldValue, newValue in
                                if !isAnalyzing && newValue.count > 2 {
                                    suggestions = mockService.searchFood(query: newValue)
                                }
                            }
                        
                        // local suggestions
                        if !suggestions.isEmpty {
                            ForEach(suggestions) { suggestion in
                                Button {
                                    applySuggestion(suggestion)
                                } label: {
                                    HStack {
                                        Text(suggestion.name).foregroundColor(.primary)
                                        Spacer()
                                        Text("\(suggestion.calories) kcal").foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }

                    // section 3: nutrition facts (filled by ai)
                    Section(header: Text("Nutrition facts")) {
                        HStack {
                            Label("Calories", systemImage: "flame.fill").foregroundColor(.orange)
                            Spacer()
                            TextField("0", text: $caloriesText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .bold()
                        }
                        
                        HStack {
                            Label("Protein", systemImage: "circle.fill").foregroundColor(.blue)
                            Spacer()
                            TextField("0", text: $proteinText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            Text("g").foregroundColor(.gray)
                        }
                        
                        HStack {
                            Label("Fats", systemImage: "circle.fill").foregroundColor(.yellow)
                            Spacer()
                            TextField("0", text: $fatsText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            Text("g").foregroundColor(.gray)
                        }
                        
                        HStack {
                            Label("Carbs", systemImage: "circle.fill").foregroundColor(.green)
                            Spacer()
                            TextField("0", text: $carbsText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            Text("g").foregroundColor(.gray)
                        }
                        
                        HStack {
                            Label("Weight", systemImage: "scalemass").foregroundColor(.gray)
                            Spacer()
                            TextField("0", text: $weightText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            Text("g").foregroundColor(.gray)
                        }
                    }
                }
                
                // loading overlay
                if isAnalyzing {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(2)
                            .tint(.white)
                        Text("AI is analyzing...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(40)
                    .background(Material.ultraThin)
                    .cornerRadius(20)
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMeal()
                    }
                    .disabled(name.isEmpty || caloriesText.isEmpty || isAnalyzing)
                    .bold()
                }
            }
            // camera sheet
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera, onImagePicked: uploadAndAnalyze)
            }
            // error alert
            .alert("Attention", isPresented: Binding<Bool>(
                get: { errorMessage != nil },
                set: { _ in errorMessage = nil }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Logic
    
    private func uploadAndAnalyze(_ image: UIImage) {
        isAnalyzing = true
        errorMessage = nil
        
        // send to server
        NetworkService.shared.analyzeImage(image: image) { result in
            DispatchQueue.main.async {
                isAnalyzing = false
                
                switch result {
                case .success(let data):
                    if data.is_food {
                        withAnimation {
                            self.name = data.name
                            self.caloriesText = "\(data.calories)"
                            self.proteinText = String(format: "%.1f", data.protein)
                            self.fatsText = String(format: "%.1f", data.fats)
                            self.carbsText = String(format: "%.1f", data.carbs)
                            self.weightText = String(format: "%.0f", data.weight_grams)
                        }
                    } else {
                        self.errorMessage = "AI did not detect food. Try a clearer photo."
                    }
                    
                case .failure(let error):
                    self.errorMessage = "Server error: \(error.localizedDescription). Check IP."
                }
            }
        }
    }
    
    private func applySuggestion(_ suggestion: FoodSuggestion) {
        self.name = suggestion.name
        self.caloriesText = String(suggestion.calories)
        self.suggestions = []
    }

    private func saveMeal() {
        guard let calories = Int(caloriesText) else { return }
        
        // save to swiftdata
        let entry = FoodEntry(name: name, calories: calories, date: Date())
        context.insert(entry)
        
        dismiss()
    }
}

// MARK: - ImagePicker Component
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    var onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.onImagePicked(uiImage)
            }
            picker.dismiss(animated: true)
        }
    }
}
