//
//  Theme.swift
//  LockedIn
//
//  Centralized theme system for colors, typography, spacing, and corner radius
//  Design sourced from Google Stitch MCP
//

import SwiftUI

// MARK: - Theme Namespace
enum Theme {
    
    // MARK: - Colors (from Stitch design)
    enum Colors {
        // Primary accent colors
        static let authority = Color(hex: "#ea2a33")      // Red - Authority/Warning (#ea2a33)
        static let execution = Color(hex: "#1a1a1a")      // Dark - Execution/Action
        
        // Background colors (from Stitch: background-dark: #0a0505)
        static let backgroundPrimary = Color(hex: "#0a0505")
        static let backgroundSecondary = Color(hex: "#0f0808")
        static let backgroundTertiary = Color(hex: "#120a0a")
        
        // Glass effect colors (from Stitch: glass-dark: rgba(18, 10, 10, 0.7))
        static let glassBackground = Color(hex: "#0f0808").opacity(0.65)
        static let glassBorder = Color.white.opacity(0.08)
        static let glassHighlight = Color.white.opacity(0.10)
        
        // Text colors (from Stitch design)
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.80)  // text-white/80
        static let textTertiary = Color.white.opacity(0.40)   // text-white/40
        static let textMuted = Color.white.opacity(0.30)      // text-white/30
        static let textSubtle = Color.white.opacity(0.50)     // text-white/50
        
        // Progress indicator colors
        static let progressActive = authority
        static let progressInactive = Color.white.opacity(0.10)  // bg-white/10
        
        // Surface colors (for cards, inputs)
        static let surfaceDark = Color(hex: "#2d1b1c")      // Dark surface for inputs/cards
        static let border = Color(hex: "#663336")          // Border color from Stitch design
    }
    
    // MARK: - Typography (from Stitch design - Inter font)
    enum Typography {
        // Font family - Inter Variable Font
        // The variable font file is Inter-VariableFont_opsz,wght.ttf
        // Use "Inter" as the family name for variable font support
        static let fontFamily = "Inter"
        
        // Display styles (text-3xl = 30px, font-bold, leading-tight, tracking-tight)
        static func displayLarge() -> Font {
            .custom(fontFamily, size: 30).weight(.bold)
        }
        
        static func displayMedium() -> Font {
            .custom(fontFamily, size: 26).weight(.bold)
        }
        
        // Headline styles
        static func headlineLarge() -> Font {
            .custom(fontFamily, size: 22).weight(.semibold)
        }
        
        static func headlineMedium() -> Font {
            .custom(fontFamily, size: 18).weight(.semibold)
        }
        
        // Body styles (text-base = 16px, font-medium, leading-relaxed)
        static func bodyLarge() -> Font {
            .custom(fontFamily, size: 16).weight(.medium)
        }
        
        static func bodyMedium() -> Font {
            .custom(fontFamily, size: 14).weight(.regular)
        }
        
        static func bodySmall() -> Font {
            .custom(fontFamily, size: 12).weight(.regular)
        }
        
        // Button styles (text-lg = 18px, font-heavy, tracking-wide, uppercase)
        // Using .black (900) weight for maximum boldness on buttons
        static func buttonLarge() -> Font {
            .custom(fontFamily, size: 18).weight(.black)
        }
        
        static func buttonMedium() -> Font {
            .custom(fontFamily, size: 15).weight(.black)
        }
        
        // Caption styles (text-[10px], uppercase, tracking-[0.2em], font-bold)
        static func caption() -> Font {
            .custom(fontFamily, size: 10).weight(.bold)
        }
        
        static func captionSmall() -> Font {
            .custom(fontFamily, size: 11).weight(.semibold)
        }
        
        // Letter spacing
        static let letterSpacingTight: CGFloat = -0.02   // tracking-tight
        static let letterSpacingNormal: CGFloat = 0
        static let letterSpacingWide: CGFloat = 0.05     // tracking-wide
        static let letterSpacingWidest: CGFloat = 0.2    // tracking-[0.2em]
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
        static let xxxxl: CGFloat = 64
        static let navLargeTitleContentTopInset: CGFloat = 4
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let none: CGFloat = 0
        static let xxxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 9999
    }
    
    // MARK: - Shadows
    enum Shadows {
        static func cardShadow() -> some View {
            Color.black.opacity(0.4)
        }
        
        static let cardShadowRadius: CGFloat = 32
        static let buttonShadowRadius: CGFloat = 20
    }
    
    // MARK: - Animation
    enum Animation {
        static let defaultDuration: Double = 0.2
        static let springResponse: Double = 0.3
        static let springDamping: Double = 0.7
        static let micro = SwiftUI.Animation.easeOut(duration: 0.18)
        static let content = SwiftUI.Animation.spring(response: 0.36, dampingFraction: 0.82)
        static let context = SwiftUI.Animation.easeInOut(duration: 0.45)
        static let snappy = SwiftUI.Animation.spring(response: 0.26, dampingFraction: 0.86)
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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
