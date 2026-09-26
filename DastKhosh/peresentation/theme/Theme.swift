//
//  Theme.swift
//  DastKhosh
//
//  Created by homan on 1405.07.02.
//



import SwiftUI
import UIKit

struct AppTheme {

    // MARK: - Brand colors

    static let emerald = Color(hex: 0x087F5B)
    static let emeraldDark = Color(hex: 0x065F46)
    static let emeraldLight = Color(hex: 0x6EE7B7)

    static let navy = Color(hex: 0x102D3A)
    static let navyDark = Color(hex: 0x0B202A)

    static let mint = Color(hex: 0x2DD4BF)
    static let ocean = Color(hex: 0x0369A1)
    static let sand = Color(hex: 0xD99A2B)
    static let coral = Color(hex: 0xDC3545)

    // MARK: - Primary

    static let primary = adaptive(
        light: 0x087F5B,
        dark: 0x6EE7B7
    )

    static let onPrimary = adaptive(
        light: 0xFFFFFF,
        dark: 0x003824
    )

    static let primaryContainer = adaptive(
        light: 0xD1F5E4,
        dark: 0x065139
    )

    static let onPrimaryContainer = adaptive(
        light: 0x003824,
        dark: 0xB5F5D7
    )

    // MARK: - Secondary

    static let secondary = adaptive(
        light: 0x366477,
        dark: 0xA7CDDF
    )

    static let onSecondary = adaptive(
        light: 0xFFFFFF,
        dark: 0x103443
    )

    static let secondaryContainer = adaptive(
        light: 0xD9EDF5,
        dark: 0x294C5C
    )

    static let onSecondaryContainer = adaptive(
        light: 0x102F3D,
        dark: 0xD9EDF5
    )

    // MARK: - Tertiary

    static let tertiary = adaptive(
        light: 0x805600,
        dark: 0xF2C46D
    )

    static let onTertiary = adaptive(
        light: 0xFFFFFF,
        dark: 0x432D00
    )

    static let tertiaryContainer = adaptive(
        light: 0xFFE8B5,
        dark: 0x604100
    )

    static let onTertiaryContainer = adaptive(
        light: 0x291A00,
        dark: 0xFFE8B5
    )

    // MARK: - Background

    static let background = adaptive(
        light: 0xF5F7F8,
        dark: 0x0D151A
    )

    static let onBackground = adaptive(
        light: 0x18242B,
        dark: 0xE2EBE7
    )

    // MARK: - Surface

    static let surface = adaptive(
        light: 0xFFFFFF,
        dark: 0x141F25
    )

    static let onSurface = adaptive(
        light: 0x18242B,
        dark: 0xE2EBE7
    )

    static let surfaceVariant = adaptive(
        light: 0xE8EFEC,
        dark: 0x2A3933
    )

    static let onSurfaceVariant = adaptive(
        light: 0x4D5F57,
        dark: 0xBACCC2
    )

    static let surfaceContainerLowest = adaptive(
        light: 0xFFFFFF,
        dark: 0x091014
    )

    static let surfaceContainerLow = adaptive(
        light: 0xF2F6F4,
        dark: 0x141F25
    )

    static let surfaceContainer = adaptive(
        light: 0xECF2EE,
        dark: 0x19262C
    )

    static let surfaceContainerHigh = adaptive(
        light: 0xE5EDE8,
        dark: 0x223137
    )

    static let surfaceContainerHighest = adaptive(
        light: 0xDEE7E1,
        dark: 0x2B3C41
    )

    // MARK: - Borders

    static let outline = adaptive(
        light: 0x73847B,
        dark: 0x85988D
    )
    static let outlineVariant = adaptive(
        light: 0xCBD8D1,
        dark: 0x3C4E45
    )

    // MARK: - Error

    static let error = adaptive(
        light: 0xBA1A1A,
        dark: 0xFFB4AB
    )

    static let onError = adaptive(
        light: 0xFFFFFF,
        dark: 0x690005
    )

    static let errorContainer = adaptive(
        light: 0xFFDAD6,
        dark: 0x93000A
    )

    static let onErrorContainer = adaptive(
        light: 0x410002,
        dark: 0xFFDAD6
    )

    // MARK: - Brand gradient

    static let brandGradient = LinearGradient(
        colors: [
            navyDark,
            navy,
            emeraldDark
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Charts

    static let chartColors: [Color] = [
        emerald,
        ocean,
        sand,
        mint,
        coral
    ]

    static let otherChartColor = Color(hex: 0x64748B)

    // MARK: - Adaptive colors

    private static func adaptive(
        light: UInt,
        dark: UInt
    ) -> Color {
        let dynamicColor = UIColor { traits in
            let hex: UInt = traits.userInterfaceStyle == .dark
            ? dark
            : light

            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255.0,
                green: CGFloat((hex >> 8) & 0xFF) / 255.0,
                blue: CGFloat(hex & 0xFF) / 255.0,
                alpha: 1.0
            )
        }

        return Color(uiColor: dynamicColor)
    }
} 

// MARK: - Hex color

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

