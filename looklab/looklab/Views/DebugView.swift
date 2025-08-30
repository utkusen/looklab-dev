import SwiftUI

struct DebugView: View {
    var body: some View {
        ZStack {
            // Test basic dark background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Debug View")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text("If you can see this, SwiftUI is working")
                    .foregroundColor(.gray)
                
                // Test our theme colors
                VStack(spacing: 10) {
                    Text("Theme Test")
                        .foregroundColor(.theme.textPrimary)
                        .padding()
                        .background(Color.theme.surface)
                        .cornerRadius(8)
                    
                    Text("Look Lab")
                        .font(.title)
                        .foregroundColor(.theme.primary)
                    
                    Button("Test Button") {
                        print("Button tapped")
                    }
                    .foregroundColor(.theme.background)
                    .padding()
                    .background(Color.theme.primary)
                    .cornerRadius(12)
                }
            }
        }
    }
}

#Preview {
    DebugView()
        .preferredColorScheme(.dark)
}