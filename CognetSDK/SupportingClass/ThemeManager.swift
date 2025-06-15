
import SwiftUI

struct ThemeManager {
    static let shared = ThemeManager()

    // Colors for light and dark mode
    enum ThemeColor: String {
        case primary = "AppGreen"
        case secondary = "AppOrange"
        case black = "AppBlack"
        case white = "AppWhite"
        case text = "AppText"
        case appNavBG = "AppNav"
        case textPlaceHolder = "AppPlaceholder"

        
        func color() -> Color {
            return Color(self.rawValue)
        }
    }

    // Example color definitions in assets
    static func color(_ themeColor: ThemeColor) -> Color {
        return themeColor.color()
    }
}


struct FrameSizeClass{
    static let normalButtonHeight = FrameSizeClass.adjustedFontSize(for: 45.0)
    static let normalTextFieldHeight = UIDevice.current.userInterfaceIdiom == .phone ? 45.0 : 70.0

    // Adjusted font size based on device
    private static func adjustedFontSize(for size: CGFloat) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        switch screenWidth {
        case 0...375: // iPhone SE or smaller
            return size * 0.9
        case 376...414: // iPhone (standard sizes)
            return size
        case 415...428: // iPhone Pro Max
            return size * 1.05
        default: // iPads or larger devices
            return size * 1.2
        }
    }

    
}
