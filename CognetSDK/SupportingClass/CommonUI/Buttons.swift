
import SwiftUI

struct PrimaryButton: View {
    var enabled:Bool = true
    var isLoading: Bool = false
    
    var title: String
    var bgColor: Color = ThemeManager.color(.secondary)
    var textColor: Color = ThemeManager.color(.white)

    var action: () -> Void
    var body: some View {
        VStack {
            ZStack{
                Button(action: {
                           // Call the action callback when the button is tapped
                           self.action()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(title)
                            .font(FontManager.customFont(.bold, size: .medium))
                            .foregroundColor(enabled ? textColor : .gray)
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(!enabled || isLoading)
            }
            .frame(height: FrameSizeClass.normalButtonHeight)
            .background(
                Rectangle()
                    .fill(enabled ? bgColor : Color.gray.opacity(0.3))
                    .cornerRadius(10)
            )
        }
    }
}
#if DEBUG
#Preview {
    PrimaryButton(title: "Primary Button", action: {
        
    })
}
#endif

struct SecondaryButton: View {
    var enabled:Bool = true

    var title: String
    var lineColor: Color = ThemeManager.color(.secondary)
    var textColor: Color = ThemeManager.color(.secondary)

    var action: () -> Void
    var body: some View {
        VStack {
            ZStack{
                RoundedRectangle(cornerRadius: 10)
                    .stroke(lineColor, lineWidth: 2)
                Button(action: {
                           // Call the action callback when the button is tapped
                           self.action()
                }) {
                    Text(title)
                        .font(FontManager.customFont(.medium, size: .medium))
                        .foregroundColor(textColor)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: FrameSizeClass.normalButtonHeight)
            
        }
        
    }
}
#if DEBUG
#Preview {
    SecondaryButton(title: "Secondary Button", action: {
        
    })
}
#endif
