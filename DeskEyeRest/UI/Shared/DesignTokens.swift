//
//  DesignTokens.swift
//  DeskEyeRest
//
//  Single source of truth for all colors, fonts, spacing values used in SwiftUI.
//  Values are the single source of truth for the app's visual language.
//

import SwiftUI

// MARK: - Colors

extension Color {
    // Dark-navy and brand-blue palette.
    // Variable names kept stable so existing call sites don't change. The
    // semantic role of each color shifted to dark-mode equivalents.
    //   inkDeep   → window deep base (almost-black with blue tint)
    //   tealDeep  → BRAND blue (the "Rest" accent)
    //   tealMid   → pressed brand blue
    //   tealSoft  → cool gray (secondary text, dividers)
    //   sand      → cloud-white (primary text on dark surfaces)
    //   sandWarm  → navy mid (sidebar / raised card surface)
    //   coral     → accent coral (alerts only)
    //   navyDeep  → in-app primary surface (Settings page bg, etc.)

    static let inkDeep   = Color(red: 0x0F/255, green: 0x14/255, blue: 0x19/255)
    static let tealDeep  = Color(red: 0x4A/255, green: 0x8F/255, blue: 0xE7/255)
    static let tealMid   = Color(red: 0x36/255, green: 0x76/255, blue: 0xC7/255)
    static let tealSoft  = Color(red: 0x89/255, green: 0x93/255, blue: 0xA8/255)
    static let sand      = Color(red: 0xEF/255, green: 0xF2/255, blue: 0xF7/255)
    static let sandWarm  = Color(red: 0x22/255, green: 0x2D/255, blue: 0x40/255)
    static let navyDeep  = Color(red: 0x1A/255, green: 0x24/255, blue: 0x34/255)
    static let coral     = Color(red: 0xE0/255, green: 0x7F/255, blue: 0x62/255)

    // Semantic aliases — these resolve to dark-mode values.
    static let surfacePrimary = navyDeep        // page backgrounds
    static let surfaceCard    = sandWarm        // raised card / sidebar
    static let surfaceDark    = inkDeep         // deepest base

    static let textPrimary   = sand             // body copy on dark surfaces
    static let textSecondary = tealSoft         // captions, meta
    static let textTertiary  = tealSoft.opacity(0.6)
    static let textOnDark    = sand             // (alias kept for clarity)

    static let brandAccent     = tealDeep       // toggles, links, focus rings
    static let attentionAccent = coral
}

// MARK: - Fonts

extension Font {
    // UI sans
    static func uiSans(_ size: CGFloat = 15) -> Font {
        .custom("WorkSans-Regular", size: size)
    }
    static func uiSansBold(_ size: CGFloat = 15) -> Font {
        .custom("WorkSans-Bold", size: size)
    }

    // Display serif (hero-only)
    static func displaySerif(_ size: CGFloat = 64) -> Font {
        .custom("InstrumentSerif-Regular", size: size)
    }
    static func displaySerifItalic(_ size: CGFloat = 36) -> Font {
        .custom("InstrumentSerif-Italic", size: size)
    }

    // Tabular mono
    static func tabularMono(_ size: CGFloat = 13) -> Font {
        .custom("JetBrainsMono-Regular", size: size)
    }
}

// MARK: - Spacing & geometry

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
    static let xxxxl: CGFloat = 64
}

enum Radius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 18
    static let xl: CGFloat = 28
}

enum Stroke {
    static let hairline: CGFloat = 1
    static let thin: CGFloat = 1.5
    static let normal: CGFloat = 2
}
