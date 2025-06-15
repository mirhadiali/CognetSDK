
import SwiftUI

struct HomeNavigationBar: View {
    let title: String
    let homeIcon:String?
    let trailingImage:String?
    let homeAction: (() -> Void)?
    let trailingAction: (() -> Void)?

    var body: some View {
        VStack {
            HStack {
                if let homeAction = homeAction, let homeIcon = homeIcon {
                    Button(action: homeAction) {
                        Image(homeIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20)
                    }
                } else {
                    Image("homeButton")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20)
                        .foregroundColor(ThemeManager.color(.text))
                }


                Text(title)
                    .font(FontManager.customFont(.medium, size: .navigation))
                    .foregroundColor(ThemeManager.color(.text))
                    .padding(.horizontal)
                Spacer()
                // Trailing Button
               
                
                
                if let trailingAction = trailingAction, let trailingImage = trailingImage {
                    Button(action: trailingAction) {
                        Image(trailingImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20)
                    }
                } else {
                    Spacer()
                        .frame(width: 10) // Placeholder space for alignment
                }
            }
            .padding(.top,40)
            .padding()
            .background(ThemeManager.color(.appNavBG))
            .shadow(radius: 3)
            .edgesIgnoringSafeArea(.all)
        }
    }
}

struct NavigationBarWithOutBackButton: View {
    let title: String
    let trailingAction: (() -> Void)?
    let trailingIcon: String?
    
    var body: some View {
        VStack {
            HStack {
                
                Image("NavLogo")
                    .resizable()
                    .frame(width: 40,height: 40)
                // Title
                Text(title)
                    .font(FontManager.customFont(.medium, size: .navigation))
                    .foregroundColor(ThemeManager.color(.text))
                    .padding(.horizontal)
                Spacer()
                // Trailing Button
                if let trailingAction = trailingAction, let trailingIcon = trailingIcon {
                    Button(action: trailingAction) {
                        Image(trailingIcon)
                    }
                } else {
                    Spacer()
                        .frame(width: 44) // Placeholder space for alignment
                }
            }
            .padding(.top,40)
            .padding()
            .background(ThemeManager.color(.appNavBG))
            .shadow(radius: 3)
            .edgesIgnoringSafeArea(.all)
        }
    }
}

struct NavigationBarWithBackButton: View {
    let title: String
    let backAction: (() -> Void)
    let trailingAction: (() -> Void)?
    let trailingIcon: String?
    
    var body: some View {
        VStack {
            HStack {
                
                Button(action: backAction) {
                    Image("backIcon")
                        .resizable()
                        .frame(width: 20,height: 20)
                }
                // Title
                Text(title)
                    .font(FontManager.customFont(.medium, size: .navigation))
                    .foregroundColor(ThemeManager.color(.text))
                    .padding(.horizontal)
                Spacer()
                // Trailing Button
                if let trailingAction = trailingAction, let trailingIcon = trailingIcon {
                    Button(action: trailingAction) {
                        Image(trailingIcon)
                    }
                } else {
                    Spacer()
                        .frame(width: 44) // Placeholder space for alignment
                }
            }
            .padding(.top,40)
            .padding()
            .background(ThemeManager.color(.appNavBG))
            .shadow(radius: 3)
            .edgesIgnoringSafeArea(.all)
        }
    }
}
#if DEBUG
#Preview {
    NavigationBarWithOutBackButton(
        title: "Home",
        trailingAction: {
            print("Settings button tapped")
        },
        trailingIcon: "gearshape.fill"
    )
}


#Preview {
    NavigationBarWithBackButton(
        title: "Home", backAction: {
            print("back button tapped")
        },
        trailingAction: {
            print("trailing button tapped")
        },
        trailingIcon: "gearshape.fill"
    )
}

#Preview {
    HomeNavigationBar(
        title: "Home",homeIcon: nil,trailingImage: nil, homeAction: nil,
        trailingAction: {
            print("trailing button tapped")
        }
    )
}
#endif

struct SuccessTickView: View {
    @State private var isVisible = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 100, height: 100)
                .scaleEffect(isVisible ? 1.2 : 0.8)
                .animation(.easeOut(duration: 0.3), value: isVisible)

            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .foregroundColor(.green)
                .frame(width: 60, height: 60)
                .scaleEffect(isVisible ? 1.0 : 0.5)
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isVisible)
        }
        .onAppear {
            isVisible = true
        }
    }
}
