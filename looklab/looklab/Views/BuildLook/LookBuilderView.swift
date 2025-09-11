import SwiftUI

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
    var onCancel: () -> Void
    var onSaved: () -> Void

    @State private var phase: LookBuildPhase = .uploading
    @State private var progress: Double = 0.12
    @State private var isDone = false
    @State private var showDetails = true

    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                header
                progressSection
                if !isDone { selectionSummary }
                Spacer(minLength: 8)
                if isDone { resultSection } else { footerButtons }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .onAppear(perform: simulateProgress)
    }

    private var header: some View {
        HStack(alignment: .center) {
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.theme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.theme.surface)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.theme.border, lineWidth: 1))
            }
            Spacer()
            VStack(spacing: 2) {
                Text(isDone ? "Your Look is Ready" : "Building your look")
                    .font(.theme.title3)
                    .foregroundColor(.theme.textPrimary)
                Text(isDone ? "Select your favorite" : phase.rawValue)
                    .font(.theme.caption2)
                    .foregroundColor(.theme.textSecondary)
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
                    ProgressRing(progress: progress)
                        .frame(width: 66, height: 66)
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
                VStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 40, weight: .regular))
                        .foregroundColor(.theme.accent)
                    Text("Generated Look Preview")
                        .font(.theme.subheadline)
                        .foregroundColor(.theme.textSecondary)
                }
            }
            .frame(height: 340)

            HStack(spacing: 12) {
                Button(action: onSaved) {
                    Label("Save to My Looks", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())

                Button(action: { /* try another variation later */ }) {
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

    private func simulateProgress() {
        // Design-only staged progress to showcase UI
        let steps: [(LookBuildPhase, Double, Double)] = [
            (.uploading, 0.12, 0.22),
            (.composing, 0.22, 0.48),
            (.generating, 0.48, 0.78),
            (.enhancing, 0.78, 0.98)
        ]
        var delay: Double = 0
        for (p, start, end) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    phase = p
                    progress = end
                }
            }
            delay += 1.0 + Double.random(in: 0.3...0.6)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.8) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                phase = .complete
                progress = 1.0
                isDone = true
            }
        }
    }
}

// MARK: - Components

private struct ProgressRing: View {
    let progress: Double // 0...1
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.theme.surfaceSecondary, lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Color.theme.primary, Color.theme.accent, Color.theme.primary]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Image(systemName: progress >= 1 ? "checkmark" : "sparkles")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.theme.primary)
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
