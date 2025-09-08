import SwiftUI

struct BundleImageView: View {
    let imagePath: String
    let size: CGSize
    var cornerRadius: CGFloat = 16
    var placeholder: String = "tshirt"
    
    var body: some View {
        ZStack {
            // Background
            ClothingImageBackground(size: size, cornerRadius: cornerRadius)
            
            // Try to load the actual image from resource bundle
            if !imagePath.isEmpty, let uiImage = loadImageFromBundle(path: imagePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.width, height: size.height)
                    .compositingGroup()
                    // Premium, subtle separation shadow
                    .shadow(
                        color: Color.black.opacity(0.28),
                        radius: max(size.width, size.height) * 0.05,
                        x: 0,
                        y: max(size.width, size.height) * 0.02
                    )
            } else {
                // Fallback to placeholder
                VStack(spacing: size.height * 0.05) {
                    Image(systemName: placeholder)
                        .font(.system(size: size.width * 0.18, weight: .medium))
                        .foregroundColor(Color.theme.accent.opacity(0.8))
                    
                    if size.height > 100 {
                        Text("Sample Item")
                            .font(.system(size: size.width * 0.06, weight: .medium, design: .rounded))
                            .foregroundColor(Color.theme.textSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.theme.border.opacity(0.4), location: 0.0),
                            .init(color: Color.theme.border.opacity(0.1), location: 1.0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    private func loadImageFromBundle(path: String) -> UIImage? {
        guard let resourcePath = Bundle.main.resourcePath else {
            print("Could not get bundle resource path")
            return nil
        }
        
        let fullPath = "\(resourcePath)/\(path)"
        
        // First try to load as UIImage directly
        if let image = UIImage(contentsOfFile: fullPath) {
            return image
        }
        
        // If that fails, try loading the data first (for WebP support)
        if let imageData = NSData(contentsOfFile: fullPath) {
            return UIImage(data: imageData as Data)
        }
        
        // Fallback: bundle may have flattened resources (no ClothingImages dirs).
        // Try to find the file by its lastPathComponent anywhere in the bundle.
        let filename = (path as NSString).lastPathComponent
        if let url = (Bundle.main.urls(forResourcesWithExtension: "webp", subdirectory: nil) ?? [])
            .first(where: { $0.lastPathComponent == filename }) {
            if let img = UIImage(contentsOfFile: url.path) {
                return img
            }
            if let data = try? Data(contentsOf: url) {
                return UIImage(data: data)
            }
        }
        
        print("Could not load image from bundle for path: \(path)")
        return nil
    }
}

struct ClothingImageBackground: View {
    let size: CGSize
    let cornerRadius: CGFloat
    
    var body: some View {
        ZStack {
            // Base: modern dark card gradient (avoids harsh light patches in dark mode)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.theme.surfaceSecondary.opacity(0.95), location: 0.0),
                            .init(color: Color.theme.surface.opacity(0.98), location: 1.0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Gentle light veil to lift overall tone for dark garments
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(0.03))
            
            // Soft central highlight to lift dark garments from the background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0.14), location: 0.0),
                            .init(color: Color.clear, location: 1.0)
                        ]),
                        center: UnitPoint(x: 0.5, y: 0.45),
                        startRadius: 0,
                        endRadius: max(size.width, size.height) * 1.05
                    )
                )
                .blendMode(.plusLighter)
            
            // Subtle directional sheen for a premium feel
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0.06), location: 0.0),
                            .init(color: Color.white.opacity(0.02), location: 0.35),
                            .init(color: Color.white.opacity(0.03), location: 1.0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        BundleImageView(
            imagePath: "ClothingImages/men/top/men_top_white_t-shirt.webp",
            size: CGSize(width: 160, height: 180)
        )
        
        BundleImageView(
            imagePath: "",
            size: CGSize(width: 160, height: 180),
            placeholder: "tshirt"
        )
    }
    .padding()
    .background(Color.theme.background)
}
