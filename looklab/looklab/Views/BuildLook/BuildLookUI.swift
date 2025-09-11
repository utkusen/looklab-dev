import SwiftUI

// Shared UI helpers for Build Look feature

struct BuildIconTitleLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon.foregroundColor(.theme.primary)
            configuration.title
        }
    }
}

struct BuildSectionHeader: View {
    let icon: String
    let title: String
    var body: some View {
        Label(title, systemImage: icon)
            .labelStyle(BuildIconTitleLabelStyle())
            .font(.theme.title3)
            .foregroundColor(.theme.textPrimary)
    }
}

struct BuildCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 14) { content }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color.theme.surface)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.theme.border, lineWidth: 1))
    }
}

struct BuildChip: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.theme.subheadline)
            .foregroundColor(.theme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.theme.surface.opacity(0.6))
            .cornerRadius(8)
    }
}

struct SelectionChip: View {
    let title: String
    var icon: String = "checkmark"
    var active: Bool = true
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold))
            Text(title).font(.theme.caption1)
        }
        .foregroundColor(active ? .theme.textPrimary : .theme.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.theme.surface)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.theme.border, lineWidth: 1))
        .cornerRadius(10)
    }
}

