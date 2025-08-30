import SwiftUI

extension Color {
    static let theme = ColorTheme()
}

struct ColorTheme {
    let background = Color("Background")
    let surface = Color("Surface")
    let surfaceSecondary = Color("SurfaceSecondary")
    let primary = Color("Primary")
    let primaryVariant = Color("PrimaryVariant")
    let secondary = Color("Secondary")
    let accent = Color("Accent")
    let textPrimary = Color("TextPrimary")
    let textSecondary = Color("TextSecondary")
    let textTertiary = Color("TextTertiary")
    let border = Color("Border")
    let error = Color("Error")
    let success = Color("Success")
    let warning = Color("Warning")
}