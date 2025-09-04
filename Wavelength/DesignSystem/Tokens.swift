import SwiftUI

// MARK: - Design Tokens
struct DesignTokens {

    // MARK: - Colors
    struct Colors {
        static let primary = Color(hex: "#6E77F7")
        static let surface = Color(hex: "#0F1115")
        static let card = Color(hex: "#171A20")
        static let textPrimary = Color(hex: "#E6E9F2")
        static let textSecondary = Color(hex: "#A8B0BF")
        static let success = Color(hex: "#33D6A6")
        static let warning = Color(hex: "#F5B759")
        static let danger = Color(hex: "#FF6B6B")
        static let border = Color(hex: "#242834")

        // Mode specific colors
        static let privateMode = Color(hex: "#33D6A6")
        static let connectedMode = Color(hex: "#6E77F7")

        // Feeling colors
        static let calm = Color(hex: "#33D6A6")
        static let tense = Color(hex: "#FF6B6B")
        static let neutral = Color(hex: "#A8B0BF")

        // Enhanced UI colors
        static let privateModeGradient = LinearGradient(
            colors: [privateMode, privateMode.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let connectedModeGradient = LinearGradient(
            colors: [connectedMode, connectedMode.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Immersive effects
        static let privateModeGlow = Color(hex: "#33D6A6").opacity(0.3)
        static let connectedModeGlow = Color(hex: "#6E77F7").opacity(0.4)
    }

    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    // MARK: - Border Radius
    struct Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 10
        static let lg: CGFloat = 14
        static let xl: CGFloat = 20
    }

    // MARK: - Typography
    struct Typography {
        static let h1 = Font.system(size: 28, weight: .semibold, design: .rounded)
        static let h2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 13, weight: .regular, design: .rounded)
        static let button = Font.system(size: 16, weight: .semibold, design: .rounded)
    }

    // MARK: - Shadows
    struct Shadows {
        static let card = Color.black.opacity(0.1)
        static let button = Color.black.opacity(0.2)
        static let privateMode = Color(hex: "#33D6A6").opacity(0.3)
        static let connectedMode = Color(hex: "#6E77F7").opacity(0.4)
    }

    // MARK: - Animations
    struct Animations {
        static let breathing = Animation.easeInOut(duration: 4).repeatForever(autoreverses: true)
        static let pulse = Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)
        static let rotation = Animation.linear(duration: 20).repeatForever(autoreverses: false)
        static let spring = Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let modeTransition = Animation.spring(response: 0.8, dampingFraction: 0.7)
    }

    // MARK: - Effects
    struct Effects {
        static let blur = 20.0
        static let glowRadius: CGFloat = 16
        static let pulseScale: CGFloat = 1.2
        static let breathingScale: CGFloat = 1.1
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:  // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
