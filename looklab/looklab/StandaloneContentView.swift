import SwiftUI

struct StandaloneContentView: View {
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 16) {
                    Text("Welcome to")
                        .font(.theme.title1)
                        .foregroundColor(.theme.textSecondary)
                    
                    Text("Look Lab")
                        .font(.theme.largeTitle)
                        .foregroundColor(.theme.primary)
                    
                    Text("Create stunning outfits with AI")
                        .font(.theme.body)
                        .foregroundColor(.theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        print("Apple Sign-In pressed - Set up Firebase to enable authentication")
                    }) {
                        HStack {
                            Image(systemName: "applelogo")
                                .font(.title2)
                            Text("Continue with Apple")
                                .font(.theme.headline)
                        }
                        .foregroundColor(.theme.background)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.theme.textPrimary)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    StandaloneContentView()
        .preferredColorScheme(.dark)
}