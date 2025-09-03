import SwiftUI

struct TestWardrobeView: View {
    @State private var selectedCategory = 0
    
    let categories = ["Tops", "Bottoms", "Shoes", "Outerwear"]
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("My Wardrobe")
                .font(.title)
                .foregroundColor(.white)
                .padding()
            
            // Simple category selector
            HStack(spacing: 12) {
                ForEach(categories.indices, id: \.self) { index in
                    Button(action: {
                        selectedCategory = index
                    }) {
                        Text(categories[index])
                            .font(.headline)
                            .foregroundColor(selectedCategory == index ? .black : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedCategory == index ? Color.white : Color.gray)
                            .cornerRadius(20)
                    }
                }
            }
            .padding()
            
            // Content area
            Text("Selected: \(categories[selectedCategory])")
                .foregroundColor(.white)
                .padding()
            
            // Simple grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(0..<4) { index in
                    VStack {
                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        Text("Item \(index + 1)")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
                }
            }
            .padding()
            
            Spacer()
        }
        .background(Color.black)
    }
}

#Preview {
    TestWardrobeView()
        .preferredColorScheme(.dark)
}