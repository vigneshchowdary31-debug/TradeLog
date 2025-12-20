import SwiftUI

struct Theme {
    static let primary = Color("BrandPrimary")
    static let background = Color("AppBackground")
    static let secondaryBackground = Color("AppSecondaryBackground")
    
    // Gradients
    static let primaryGradient = LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let successGradient = LinearGradient(colors: [Color.green.opacity(0.8), Color.green], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let dangerGradient = LinearGradient(colors: [Color.red.opacity(0.8), Color.red], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardGradient = LinearGradient(colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.5)], startPoint: .top, endPoint: .bottom)
}

extension Color {
    // Fallbacks if assets aren't created yet, though we should prefer using Assets.xcassets ideally.
    // For now, mapping to system colors for safety if asset catalog isn't updated.
    static let brandPrimary = Color.blue
    static let appBackground = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
}
