
import SwiftUI

#Preview{
    ToastView(toastData: ToastModel(message: "Test"))
}

// MARK: - Toast View
struct ToastView: View {
    var toastData: ToastModel
    
    var body: some View {
        Text(toastData.message ?? "")
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(.white)
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background(toastData.code.bgColor)
            .cornerRadius(10)
            .shadow(radius: 4)
            .padding(.top, 20)
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let toastData: ToastModel
    
    
    func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    if isPresented {
                        ToastView(toastData: toastData)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + (toastData.duration ?? 3.0)) {
                                    withAnimation { isPresented = false }
                                }
                            }
                    }
                    Spacer()
                }
            )
    }
}

// MARK: - Toast View Extension
extension View {
    func showToast(isPresented: Binding<Bool>, toastData: ToastModel) -> some View {
        self.modifier(ToastModifier(isPresented: isPresented, toastData: toastData))
    }
}

// MARK: - Image Popup View
struct ImageViewPopup: View {
    let image: UIImage?
    var closeAction: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture { withAnimation { closeAction() } }
            
            VStack {
                Spacer()
                VStack {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(10)
                            .shadow(radius: 8)
                            .padding()
                    }
                    
                    Button(action: { withAnimation { closeAction() } }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.gray)
                            .padding(.bottom, 10)
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
                Spacer()
            }
        }
    }
}

struct ImageViewHandler: View {
    @State private var showAlert = false
    var closeAction: (Bool, Int) -> Void
    var image: UIImage?
    
    var body: some View {
        ZStack {
            if showAlert {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            showAlert = false
                        }
                    }
                
                ImageViewPopupView(
                    closeAction: { success, index in
                        closeAction(success, index)
                        withAnimation {
                            showAlert = false
                        }
                    }, image: image,
                    showTopClose: true
                )
                .transition(.move(edge: .bottom).combined(with: .opacity)) // Corrected transition syntax
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                showAlert = true
            }
        }
    }
    

    static private var existingHostingController: UIHostingController<ImageViewHandler>?
    
    static func showPopUp(image: UIImage, completion: @escaping (Bool, Int) -> Void) {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        
        // Remove existing hosting controller if present
        if let existingController = existingHostingController {
            existingController.view.removeFromSuperview()
            existingController.removeFromParent()
            existingHostingController = nil
        }
        
        // Create and add new hosting controller
        let retryView = ImageViewHandler(closeAction: { success, value in
            UIView.animate(withDuration: 0.5, animations: {
                existingHostingController?.view.alpha = 0
            }) { _ in
                existingHostingController?.view.removeFromSuperview()
                existingHostingController?.removeFromParent()
                existingHostingController = nil
                completion(success, value)
                
            }
        }, image: image)
        
        let hostingController = UIHostingController(rootView: retryView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.frame = window.bounds
        
        window.addSubview(hostingController.view)
        window.rootViewController?.addChild(hostingController)
        
        existingHostingController = hostingController
    }
    
}
struct ImageViewPopupView: View {

    var closeAction: (Bool, Int) -> Void
    var image: UIImage?
    var showTopClose: Bool = false
    var hideTabBar: Bool = false

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.2)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        self.closeAction(false, 0)
                    }
                }
            
            VStack {
                Spacer()
                VStack(alignment: .center, spacing: 16) {
                    // Optional top close button and title
                    if showTopClose {
                        HStack {
                         
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    self.closeAction(false, 0)
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 10)
                            }
                        }
                        .padding(.top, 20)
                    }

                    // Optional image
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.green)
                            .padding(.vertical).padding(.bottom,20)
                    }

                    

                }
               // .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 10)
               // .padding(.horizontal, 20)
              //  .padding(.vertical, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity)) // Corrected transition syntax
                .onAppear {
                    
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showTopClose) // Corrected animation syntax
    }
}



struct ToastModel: Error {
    var message: String? = ""
    var duration : Double? = 3.0
    var code : ToastType = .information
    var description: String? {
        return message
    }
}

enum ToastType{
    case validation
    case alert
    case success
    case information
    
    var bgColor: Color{
        switch self{
        case .alert:
            return ThemeManager.color(.secondary)
        case .validation:
            return ThemeManager.color(.secondary)
        case .success,.information:
            return ThemeManager.color(.primary)
        }
    }
}
