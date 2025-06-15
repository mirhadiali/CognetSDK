


import SwiftUI
import AVFoundation

struct HandScanView: View {
   
    @ObservedObject var vmHome:CaptureProcessHomeViewModel
    @State private var showDatePicker = false
    var action:()->Void
    var captureType:CaptureType = .hand
    @StateObject var cameraModel = CameraModel(type: .hand)
    @State private var isScaled = false

    var body: some View {
        ZStack{
            VStack(alignment: .center, spacing: 16) {
                // Step Indicator
//                if vmHome.progressStep.rawValue > 0 {
//                    
//                    HStack{
//                    Text("Step \(vmHome.totalStep.firstIndex(of: .hand)!)/\(vmHome.totalStep.count-1)")
//                        .font(FontManager.customFont(.bold, size: .small))
//                        .foregroundColor(ThemeManager.color(.text))
//                        .padding(.top)
//                        Spacer()
//                    }
//                }

                // Progress Bar
                if vmHome.progressStep.rawValue > 0 {
                    
                    ProgressView(value: Float(vmHome.progressStep.rawValue)/Float(vmHome.totalStep.count)) // 20% Progress for Step 1 of 5
                        .progressViewStyle(LinearProgressViewStyle(tint: ThemeManager.color(.secondary)))
                        .frame(height: 4)
                        .background(ThemeManager.color(.white).opacity(0.7))
                        .cornerRadius(2)
                }
                
                HStack(alignment: .center){
                    Image("palm")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color("icon4"))
                        .frame(width: 50, height: 50)

                // Instruction Text
                Text("Capture Hand Image")
                    .font(FontManager.customFont(.bold, size: .medium))
                    .foregroundColor(ThemeManager.color(.text))
                    Spacer()
                }.padding(.top)
                Divider()
                    .frame(height: 1)
                    .background(ThemeManager.color(.text))
                
                if let imageData = vmHome.handImage{
                    if vmHome.showedSuccessImage == false{
                    //    GIFPlayerView(gifName: "successTick")
                        SuccessTickView()
                            .padding(.top,40)
                            .onAppear(perform: {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    withAnimation{
                                        vmHome.showedSuccessImage = true
                                    }
                                }
                            }).transition(.opacity)

                       
                    }else{
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: imageData)
                                .resizable()
                                .scaledToFill()
                                .frame(height: vmHome.getHeight(captureType: captureType))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            Button(action: {
                                vmHome.showedLoaderImage = false
                                isScaled = false
                                vmHome.handImage = nil // Remove image
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(ThemeManager.color(.secondary))
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .padding(5)
                            }
                        }
                        PrimaryButton(isLoading: vmHome.showLoader, title: vmHome.getButtonTitle, action: {
                            vmHome.showedLoaderImage = false
                            switch vmHome.state {
                            case .biometric:
                                vmHome.handBiometricLogin(succesCompletion: action)
                            case .onboarding:
                                vmHome.handVerifyAndSearch(succesCompletion: action)
                            case .verification:
                                vmHome.biometricVerify(image: vmHome.handImage, succesCompletion: action)
                            }
                            
                        }).padding()
                    }
                }else{
                    if vmHome.showedLoaderImage == false{
                        VStack{
                            Image("palm")
                                .resizable()
                                .scaledToFit()
                                .padding()
                                .foregroundColor(ThemeManager.color(.white))
                                .scaleEffect(isScaled ? 1.0 : 0.3) // Scale effect
                                .animation(.easeInOut(duration: 2.0), value: isScaled)
                                .onAppear(perform: {
                                    isScaled = true

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                        withAnimation{
                                            vmHome.showedSuccessImage = false
                                            vmHome.showedLoaderImage = true
                                        }
                                    }
                                })
                            HStack{
                                Spacer()
                                ProgressView()
                                    .foregroundColor(ThemeManager.color(.white))
                                    .frame(width: 30,height: 30)
                                Spacer()
                            }
                        }.transition(.scale)
                    }else{
                        
                        CameraView(cameraModel: cameraModel ,action: { image, handSide in
                            withAnimation{
                                vmHome.showedSuccessImage = false

                                vmHome.handImage = image
                                vmHome.handSide = handSide
                            }
                        }, reloadManager: ReloadManager())
                    }
                }
                Spacer()

            }
            .padding()
            .frame(height: UIScreen.main.bounds.height - 150)

            .background(
                ZStack{
                   // GradientBackground()
                    ThemeManager.color(.white).opacity(0.1)
                        .cornerRadius(20)
                   // RoundedRectangle(cornerRadius: 20).fill(ThemeManager.color(.white)) // Translucent background

                }
            )
            
        }
        .commonAlert(isPresented: $vmHome.showErrorAlert, alert: AlertViewModel(alertTitle: "Error",alertMessage: vmHome.errorMessage))
    }

}


#if DEBUG
#Preview {
    HandScanView(vmHome: CaptureProcessHomeViewModel(configurations: Configurations.mock(), biometricData: nil, state: .onboarding, completion: {_ in}, biometricResponseCompletion: {_,_ in}, verificationResponseCompletion: {_ in}), action: {
        
    })
        
}
#endif
