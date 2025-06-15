


import SwiftUI
import AVFoundation

struct ConfirmScanView: View {
   
    @ObservedObject var vmHome:CaptureProcessHomeViewModel
    @State private var showDatePicker = false
    var action:()->Void
   
    var body: some View {
        ZStack{
            VStack(alignment: .center, spacing: 16) {
                // Step Indicator
//                if vmHome.progressStep.rawValue > 0 {
//                    HStack{
//                        
//                        Text("Step \(vmHome.totalStep.firstIndex(of: .complete)!)/\(vmHome.totalStep.count-1)")
//                            .font(FontManager.customFont(.bold, size: .small))
//                            .foregroundColor(ThemeManager.color(.text))
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
                
                HStack{

                // Instruction Text
                    Text(vmHome.showedSuccessImage == false ? "Confirm to proceed" : "Confirmed")
                    .font(FontManager.customFont(.bold, size: .medium))
                    .foregroundColor(ThemeManager.color(.text)).padding(.top)
                    Spacer()
                }
                
                Divider()
                    .frame(height: 1)
                    .background(ThemeManager.color(.text))
                
                VStack(spacing: 0){
                    if vmHome.showedconfirm == true{
                        ZStack{
                            GIFPlayerView(gifName: "successTick")
                               
                                .cornerRadius(20)
                                .frame(width: 250, height: 200)
                                .onAppear(perform: {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                                        withAnimation{
                                            vmHome.docImage = nil
                                            vmHome.faceImage = nil
                                            vmHome.faceHandImage = nil
                                            vmHome.handImage = nil
                                            vmHome.frontId = nil
                                            vmHome.backId = nil
                                            
                                            
                                            vmHome.showedSuccessImage = false
                                            vmHome.progressStep = .info
                                        }
                                    }
                                }).transition(.opacity)
                        }
                    }else{
                        VStack(spacing: 0){
                            
                            if let doc = vmHome.docImage{
                                HStack{
                                    
                                    Text("Document Image")
                                        .font(FontManager.customFont(.medium, size: .normal))
                                        .foregroundColor(ThemeManager.color(.text)).padding(.top)
                                        .padding(.vertical)
                                    Spacer()
                                    
                                }
                                HStack{
                                    Image(uiImage: doc)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit )
                                        .frame(height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    Spacer()
                                }
                            } else if let frontId = vmHome.frontId, let backId = vmHome.backId {
                                HStack{
                                    
                                    Text("Document Image")
                                        .font(FontManager.customFont(.medium, size: .normal))
                                        .foregroundColor(ThemeManager.color(.text)).padding(.top)
                                        .padding(.vertical)
                                    Spacer()
                                    
                                }
                                HStack{
                                    Image(uiImage: frontId)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit )
                                        .frame(height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    Image(uiImage: backId)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit )
                                        .frame(height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    Spacer()
                                }
                            }
                            
                            if let face = vmHome.faceImage{
                                HStack{
                                    Text("Face Image")
                                        .font(FontManager.customFont(.medium, size: .normal))
                                        .foregroundColor(ThemeManager.color(.text)).padding(.top)
                                        .padding(.vertical)
                                    Spacer()
                                    
                                }
                                HStack{
                                    Image(uiImage: face)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit )
                                        .frame(height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    Spacer()
                                    
                                }
                            }
                            
                            if let face = vmHome.faceHandImage{
                                HStack{
                                    Text("Face & Hand Image")
                                        .font(FontManager.customFont(.medium, size: .normal))
                                        .foregroundColor(ThemeManager.color(.text)).padding(.top)
                                        .padding(.vertical)
                                    Spacer()
                                    
                                }
                                HStack{
                                    Image(uiImage: face)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit )
                                        .frame(height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    Spacer()
                                    
                                }
                            }
                            
                            if let hand = vmHome.handImage{
                                HStack{
                                    Text("Hand Image")
                                        .font(FontManager.customFont(.medium, size: .normal))
                                        .foregroundColor(ThemeManager.color(.text)).padding(.top)
                                        .padding(.vertical)
                                    Spacer()
                                    
                                }
                                HStack{
                                    Image(uiImage: hand)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit )
                                        .frame(height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    Spacer()
                                    
                                }
                            }
                        }
                        PrimaryButton(title: vmHome.getButtonTitle, action: {
                            vmHome.showedconfirm = true
                            vmHome.returnResponse(action: action)
                            
                        }).padding()
                    }
                }
                    
                
            }
            .padding()
            .background (
                ZStack{
                    GradientBackground()
                        .cornerRadius(20)
                   // RoundedRectangle(cornerRadius: 20).fill(ThemeManager.color(.white)) // Translucent background

                }
            )
            
        }
    }

}


#if DEBUG
#Preview {
    HandScanView(vmHome: CaptureProcessHomeViewModel(configurations: Configurations.mock(), biometricData: nil, state: .onboarding, completion: {_ in}, biometricResponseCompletion: {_,_ in}, verificationResponseCompletion: {_ in}), action: {
        
    })
        
}
#endif
