import SwiftUI
import SwiftData

enum LookBuildPhase: String, CaseIterable {
    case uploading = "Uploading items"
    case composing = "Setting background"
    case generating = "Generating look"
    case enhancing = "Enhancing details"
    case complete = "Complete"
}

struct LookBuilderView: View {
    let selectedItems: [ClothingItem]
    let background: BackgroundType
    var envInfo: String? = nil
    var onCancel: () -> Void
    var onSaved: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var phase: LookBuildPhase = .uploading
    @State private var progress: Double = 0.12
    @State private var isDone = false
    @State private var showDetails = true
    @State private var generatedImage: UIImage?
    @State private var isSpinning = false

    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                header
                if !isDone { progressSection }
                if !isDone { selectionSummary }
                if !isDone { Spacer(minLength: 8) }
                if isDone { resultSection } else { footerButtons }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .onAppear(perform: startBuild)
        .safeAreaInset(edge: .top) {
            // Add consistent breathing room below the sheet’s top edge across devices
            Color.clear.frame(height: 12)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            // Left spacer to keep title centered (matches chevron width)
            Color.clear.frame(width: 36, height: 36)
            Spacer()
            VStack(spacing: 2) {
                Text(isDone ? "Your Look is Ready" : "Building Your Look")
                    .font(.theme.title3)
                    .foregroundColor(.theme.textPrimary)
                if !isDone {
                    Text(phase.rawValue)
                        .font(.theme.caption2)
                        .foregroundColor(.theme.textSecondary)
                }
            }
            Spacer()
            Button(action: { withAnimation { showDetails.toggle() } }) {
                Image(systemName: showDetails ? "chevron.down" : "chevron.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.theme.textSecondary)
                    .frame(width: 36, height: 36)
            }
        }
    }

    private var progressSection: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.theme.border, lineWidth: 1))
                    .frame(height: 120)

                HStack(spacing: 16) {
                    if !isDone {
                        // Single self-animating spinner during build
                        IndeterminateSpinner()
                            .frame(width: 66, height: 66)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.theme.primary)
                            .frame(width: 66, height: 66)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isDone ? "Done" : phase.rawValue)
                            .font(.theme.headline)
                            .foregroundColor(.theme.textPrimary)
                        Text(hint(for: phase))
                            .font(.theme.caption1)
                            .foregroundColor(.theme.textSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
            }

            if !isDone {
                Text("This usually takes about 8 seconds")
                    .font(.theme.caption2)
                    .foregroundColor(.theme.textSecondary)
            }

            if showDetails && !isDone {
                PhaseSteps(current: phase)
            }
        }
    }

    private var selectionSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { BuildSectionHeader(icon: "tshirt", title: "Selections"); Spacer() }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(selectedItems, id: \.id) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            BundleImageView(
                                imagePath: item.imageURL ?? "",
                                size: CGSize(width: 120, height: 140),
                                cornerRadius: 14,
                                placeholder: item.category.iconName
                            )
                            Text(item.name)
                                .font(.theme.caption1)
                                .foregroundColor(.theme.textPrimary)
                                .lineLimit(1)
                            Text(item.category.displayName)
                                .font(.theme.caption2)
                                .foregroundColor(.theme.textSecondary)
                        }
                        .frame(width: 120)
                    }
                }
                .padding(.vertical, 4)
            }

            // Background chip removed per design
        }
        .padding(16)
        .background(Color.theme.surface)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.theme.border, lineWidth: 1))
        .cornerRadius(16)
    }

    private var resultSection: some View {
        VStack(spacing: 16) {
            // Placeholder generated image area (pager-ready later)
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.theme.border, lineWidth: 1))
                if let img = generatedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 340)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(6)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 40, weight: .regular))
                            .foregroundColor(.theme.accent)
                        Text("Generated Look Preview")
                            .font(.theme.subheadline)
                            .foregroundColor(.theme.textSecondary)
                    }
                }
            }
            .frame(height: 340)

            // Primary action: Save
            Button(action: saveLook) {
                Label("Save to My Looks", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())

            // Secondary actions: Re-Create and Try Another
            HStack(spacing: 12) {
                Button(action: recreate) {
                    Label("Re-Create", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())

                Button(action: { onCancel() }) {
                    Label("Try Another", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(.bottom, 12)
    }

    private var footerButtons: some View {
        HStack(spacing: 12) {
            Button(action: onCancel) {
                Label("Cancel", systemImage: "xmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())

            Button(action: { /* no-op during design */ }) {
                Label("Building…", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(true)
        }
        .padding(.bottom, 8)
    }

    private func hint(for phase: LookBuildPhase) -> String {
        switch phase {
        case .uploading: return "Preparing items for AI"
        case .composing: return "Applying \(background.displayName.lowercased())"
        case .generating: return "Rendering your outfit"
        case .enhancing: return "Improving lighting and edges"
        case .complete: return "All set"
        }
    }

    private func startBuild() {
        // Progress animation while building
        animateProgress()
        Task {
            do {
                let user = users.sorted(by: { $0.updatedAt > $1.updatedAt }).first
                print("LookBuilder background raw=\(background.rawValue) name=\(background.displayName)")
                let effectiveEnv = envInfo ?? background.envInfoText
                print("LookBuilder startBuild envInfo=\(effectiveEnv)")
                let image = try await FirebaseManager.shared.buildLook(selectedItems: selectedItems, envInfo: effectiveEnv, user: user)
                await MainActor.run {
                    generatedImage = image
                    phase = .complete
                    progress = 1.0
                    isDone = true
                }
            } catch {
                // In a real app, surface error UI. For now, mark complete without image.
                await MainActor.run {
                    phase = .complete
                    progress = 1.0
                    isDone = true
                }
            }
        }
    }

    private func recreate() {
        // Reset state and start the build again with the same inputs
        generatedImage = nil
        isDone = false
        phase = .uploading
        progress = 0.12
        showDetails = true
        startBuild()
    }

    private func animateProgress() {
        // Smooth, even pacing across phases ~8s total pre-completion
        isSpinning = true
        let phaseSchedule: [(LookBuildPhase, Double)] = [
            (.uploading, 0.2),
            (.composing, 0.45),
            (.generating, 0.7),
            (.enhancing, 0.9)
        ]
        var delay: Double = 0
        for (p, end) in phaseSchedule {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard !isDone else { return }
                withAnimation(.easeInOut(duration: 0.9)) {
                    phase = p
                    progress = end
                }
            }
            delay += 2.0
        }
    }

    private func saveLook() {
        guard let image = generatedImage else { return }
        // Persist image locally and create a Look entry
        if let path = saveImageToDocuments(image: image) {
            let look = Look(userID: selectedItems.first?.userID ?? UUID().uuidString,
                            name: "My Look",
                            clothingItemIDs: selectedItems.map { $0.id },
                            backgroundType: background)
            look.generatedImageURLs = [path]
            look.selectedImageURL = path
            modelContext.insert(look)
            try? modelContext.save()
        }
        onSaved()
    }

    private func saveImageToDocuments(image: UIImage) -> String? {
        guard let data = image.pngData() ?? image.jpegData(compressionQuality: 0.92) else { return nil }
        let filename = "generated_look_\(UUID().uuidString).png"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(filename)
        guard let url else { return nil }
        do {
            try data.write(to: url)
            return url.path
        } catch {
            return nil
        }
    }
}

// MARK: - Components

private struct IndeterminateSpinner: View {
    @State private var rotate = false
    var body: some View {
        Circle()
            .trim(from: 0.1, to: 0.9)
            .stroke(Color.theme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .rotationEffect(.degrees(rotate ? 360 : 0))
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    rotate = true
                }
            }
    }
}

// Shared UI helpers are in BuildLookUI.swift

private struct PhaseSteps: View {
    let current: LookBuildPhase
    private let all: [LookBuildPhase] = [.uploading, .composing, .generating, .enhancing]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(all, id: \.self) { step in
                HStack(spacing: 10) {
                    Image(systemName: icon(for: step))
                        .foregroundColor(color(for: step))
                        .frame(width: 22)
                    Text(step.rawValue)
                        .font(.theme.subheadline)
                        .foregroundColor(.theme.textPrimary)
                    Spacer()
                }
                .padding(10)
                .background(rowBackground(for: step))
                .cornerRadius(10)
            }
        }
        .padding(12)
        .background(Color.theme.surface)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.theme.border, lineWidth: 1))
        .cornerRadius(12)
    }

    private func icon(for step: LookBuildPhase) -> String { step == current ? "arrow.triangle.2.circlepath" : "checkmark" }
    private func color(for step: LookBuildPhase) -> Color { step == current ? .theme.accent : .theme.textSecondary }
    private func rowBackground(for step: LookBuildPhase) -> Color { step == current ? Color.theme.primary.opacity(0.06) : Color.clear }
}

// Preview
#Preview {
    let items: [ClothingItem] = [
        ClothingItem(userID: "p", name: "White Tee", category: .tops, imageURL: "ClothingImages/men/top/men_top_white_t-shirt.webp"),
        ClothingItem(userID: "p", name: "Black Jeans", category: .bottoms, imageURL: "ClothingImages/men/bottom/men_bottom_black_jeans.webp"),
        ClothingItem(userID: "p", name: "Canvas Shoes", category: .shoes, imageURL: "ClothingImages/men/shoe/men_shoe_white_canvas_shoes.webp"),
        ClothingItem(userID: "p", name: "Sunglasses", category: .accessories, imageURL: "")
    ]
    return LookBuilderView(
        selectedItems: items,
        background: .street,
        onCancel: {},
        onSaved: {}
    )
    .preferredColorScheme(.dark)
}
