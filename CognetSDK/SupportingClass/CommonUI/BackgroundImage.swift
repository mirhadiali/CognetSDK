
import SwiftUI

struct BackgroundImageView: View {
    var imageName: String?

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [ThemeManager.color(.appNavBG),ThemeManager.color(.textPlaceHolder), ThemeManager.color(.appNavBG)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
          
        }
//        GeometryReader { geometry in
//            if let img = imageName{
//                Image(img)
//                    .resizable()
//                    .foregroundColor(.white)
//                    .aspectRatio(contentMode: .fill)
//                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
//                    .edgesIgnoringSafeArea(.all)
//            }
//        }
//        .background(ThemeManager.color(.primary))
    }
}
#if DEBUG
#Preview {
    GradientBackground()
   // BackgroundImageView(imageName: "SplashBG")
}
#endif
struct GradientBackground: View {
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [ThemeManager.color(.appNavBG).opacity(0.4),ThemeManager.color(.textPlaceHolder).opacity(0.4), ThemeManager.color(.appNavBG).opacity(0.4)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
          
        }
    }
}
