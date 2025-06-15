//
//  FontManager.swift


import SwiftUI

struct FontManager {
    // Custom font names
    enum CustomFont: String {
        case light = "SourceSansPro-Light"
        case regular = "SourceSansPro-Regular"
        case bold = "SourceSansPro-Bold"
        case italic = "SourceSansPro-Italic"
        case medium = "SourceSansPro-Semibold"
    }

    // Font sizes
    enum FontSize: CGFloat {
        case small = 12
        case normal = 14
        case medium = 16
        case navigation = 18
        case large = 20
        case extraLarge = 24
    }

    // Adjusted font size based on device
    private static func adjustedFontSize(for size: FontSize) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width

        switch screenWidth {
        case 0...375: // iPhone SE or smaller
            return size.rawValue * 0.9
        case 376...414: // iPhone (standard sizes)
            return size.rawValue
        case 415...428: // iPhone Pro Max
            return size.rawValue * 1.1
        default: // iPads or larger devices
            return size.rawValue * 1.2
        }
    }

    // Custom font method
    static func customFont(_ font: CustomFont, size: FontSize) -> Font {
        let adjustedSize = adjustedFontSize(for: size)
        return Font.custom(font.rawValue, size: adjustedSize)
    }
}
