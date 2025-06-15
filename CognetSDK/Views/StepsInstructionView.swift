


import SwiftUI

struct StepsInstructionView: View {
   
    @ObservedObject var vmHome:CaptureProcessHomeViewModel
    @State private var showDatePicker = false
    var action:()->Void
    var body: some View {
        ZStack{
            VStack(alignment: .leading, spacing: 16) {
                // Step Indicator
//                if vmHome.progressStep.rawValue > 0 {
//                    Text("Step \(vmHome.progressStep.rawValue)/\(vmHome.totalStep.count-1)")
//                        .font(FontManager.customFont(.bold, size: .small))
//                        .foregroundColor(ThemeManager.color(.text))
//                        .padding(.top)
//                }

                // Progress Bar
                if vmHome.progressStep.rawValue > 0 {
                    
                    ProgressView(value: Float(vmHome.progressStep.rawValue)/Float(vmHome.totalStep.count)) // 20% Progress for Step 1 of 5
                        .progressViewStyle(LinearProgressViewStyle(tint: ThemeManager.color(.secondary)))
                        .frame(height: 4)
                        .background(ThemeManager.color(.white).opacity(0.7))
                        .cornerRadius(2)
                }
                
                
                // Instruction Text
                Text("Onboarding Process Steps")
                    .font(FontManager.customFont(.bold, size: .medium))
                    .foregroundColor(ThemeManager.color(.text)).padding(.top)
                
                Divider()
                    .frame(height: 1)
                    .background(ThemeManager.color(.text))
                if let index = vmHome.totalStep.firstIndex(of: .passport) {
                    InstructionView(step: "\(index). Capture Passport",
                                    description: "Make sure a valid passport is ready for scanning.",
                                    animation: "card",color:"icon1")//icon: "doc.text.viewfinder"//lottie1
                } else if let index = vmHome.totalStep.firstIndex(of: .idcard) {
                    InstructionView(step: "\(index). Capture ID Card",
                                    description: "Make sure a valid ID card is ready for scanning.",
                                    animation: "card",color:"icon1")//icon: "doc.text.viewfinder"//lottie1
                }
                if let index = vmHome.totalStep.firstIndex(of: .face) {
                    InstructionView(step: "\(index). Capture Live Face Image",
                                    description: "Make sure to capture in a well-lit environment.",
                                    animation: "face",color:"icon2")// icon: "person.crop.circle"//lottie4
                }
                
                if let index = vmHome.totalStep.firstIndex(of: .faceHand) {
                    InstructionView(step: "\(index). Capture Live Face Image with hand holding up",
                                    description: "Make sure to capture in a well-lit environment. Make sure hand holding up and visible ",
                                    animation: "facepalm",color:"icon3")// icon: "person.crop.circle"//Handscnene
                }
                if let index = vmHome.totalStep.firstIndex(of: .hand) {
                    InstructionView(step: "\(index). Capture Hand Image",
                                    description: "Capture the image of your palm.",
                                    animation: "palm",color:"icon4")//icon: "hand.raised.fill"//lottie3
                }
                Spacer()
                PrimaryButton(title: vmHome.getButtonTitle, action: {
                    vmHome.showedLoaderImage = false
//                    vmHome.showedSuccessImage = false
                    action()
                    
                }).padding()
                .padding(.bottom ,20)
            }
            .padding()
            .frame(height: UIScreen.main.bounds.height - 150)
            .background(
                //  GradientBackground()

                ThemeManager.color(.white).opacity(0.1)
                    .cornerRadius(20)
                
              //  RoundedRectangle(cornerRadius: 20)
                 //   .fill(GradientBackground) // Translucent background
            )

            
        }
    }
    

    
    struct InstructionView: View {
        let step: String
        let description: String
      //  let icon: String
        let animation:String
        let color:String

        var body: some View {
            HStack {
                Image(animation)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(Color(color))
                    .padding(.horizontal,10)
                
//                LottieViewUI(animationName: animation, loopMode: .loop, frameSize: CGSize(width: 50, height: 50))
//                    .frame(width: 50, height: 50)
               
                VStack(alignment: .leading,spacing: 10) {
                    Text(step)
                        .font(FontManager.customFont(.bold, size: .medium))
                        .foregroundColor(ThemeManager.color(.text))
                    
                    Text(description)
                        .font(FontManager.customFont(.regular, size: .medium))
                        .foregroundColor(ThemeManager.color(.text))
                }
            }.padding(.vertical)
        }
    }
}


#if DEBUG
#Preview {
    StepsInstructionView(vmHome: CaptureProcessHomeViewModel(configurations: Configurations.mock(), biometricData: nil, state: .onboarding, completion: {_ in}, biometricResponseCompletion: {_,_ in}, verificationResponseCompletion: {_ in}), action: {
        
    })
        
}
#endif
