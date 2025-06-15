

import SwiftUI

public struct CaptureProcessHomeView: View {
    @EnvironmentObject var loaderVM: LoaderViewModel
    
    @StateObject public var vmHome: CaptureProcessHomeViewModel
    @Environment(\.presentationMode) var presentationMode
    
    public init(vmHome: CaptureProcessHomeViewModel) {
        _vmHome = StateObject(wrappedValue: vmHome)
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                BackgroundImageView(imageName: "Bg")
                VStack {
                    if vmHome.progressStep == .info || vmHome.progressStep == vmHome.totalStep.last{
                        
                        HomeNavigationBar(
                            title: getNavTitle,homeIcon:"homeButton",trailingImage: nil, homeAction: {
                                //                                if vmHome.progressStep == vmHome.totalStep.last{
                                withAnimation{
                                    presentationMode.wrappedValue.dismiss()
                                    //                                        vmHome.progressStep = vmHome.totalStep.first ?? .info
                                }
                                //                                }
                            },
                            trailingAction: {
                                print("trailing button tapped")
                            }
                        )
                    }else{
                        NavigationBarWithBackButton(title: getNavTitle, backAction: {
                            if vmHome.progressStep != .info && vmHome.progressStep != vmHome.totalStep.last{
                                vmHome.previousStep()
                                
                            }
                            if vmHome.progressStep == vmHome.totalStep.last{
                                withAnimation{
                                    vmHome.progressStep = .info
                                }
                            }
                        }, trailingAction: nil, trailingIcon: nil)
                    }
                    
                    ScrollView {
                        
                        VStack{
                            switch vmHome.progressStep{
                            case .info:
                                StepsInstructionView(vmHome: vmHome, action: {
                                    withAnimation{
                                        vmHome.nextStep()
                                    }
                                }).padding()
                            case .passport, .idcard:
                                DocumentScanView(vmHome: vmHome, action: {
                                    withAnimation{
                                        vmHome.nextStep()
                                        vmHome.resetNFC()
                                    }
                                }).padding(.vertical)
                                    .padding(.horizontal)
                                
                            case .face:
                                FaceScanView(vmHome: vmHome, action: {
                                    withAnimation{
                                        switch vmHome.state {
                                        case .biometric, .verification:
                                            withAnimation{
                                                self.presentationMode.wrappedValue.dismiss()
                                            }
                                        case .onboarding:
                                            vmHome.nextStep()
                                        }
                                    }
                                }).padding()
                            case .faceHand:
                                FaceHandScanView(vmHome: vmHome, action: {
                                    withAnimation{
                                        vmHome.nextStep()
                                    }
                                }).padding()
                            case .hand:
                                HandScanView(vmHome: vmHome, action: {
                                    switch vmHome.state {
                                    case .biometric, .verification:
                                        withAnimation{
                                            self.presentationMode.wrappedValue.dismiss()
                                        }
                                    case .onboarding:
                                        vmHome.nextStep()
                                    }
                                }).padding()
                                
                            case .complete:
                                ConfirmScanView(vmHome: vmHome, action: {
                                    withAnimation{
                                        self.presentationMode.wrappedValue.dismiss()
                                    }
                                }).padding()
                                
                            default:
                                StepsInstructionView(vmHome: vmHome, action: {
                                    withAnimation{
                                        if let currentIndex = vmHome.totalStep.firstIndex(of: vmHome.progressStep),
                                           currentIndex < vmHome.totalStep.count - 1 {
                                            vmHome.progressStep = vmHome.totalStep[currentIndex + 1]
                                        }
                                    }
                                }).padding()
                                
                            }
                        }.transition(.opacity)
                        
                        
                    }
                    
                }
                .showToast(isPresented: $vmHome.showToast, toastData: vmHome.toastData ?? .init())
            }
            .navigationBarHidden(true)
            .edgesIgnoringSafeArea(.all)
            .onAppear(){
                
            }
        }
        
    }
    
    var getNavTitle: String{
        switch vmHome.progressStep{
        case .info:
            return "Onboard Customer"
        case .idcard, .passport:
            return "Capture Document"
        case .face:
            return "Capture Face"
        case .faceHand:
            return "Capture Face and Hand"
        case .hand:
            return "Capture Hand"
        case .complete:
            return "Verification"
        default:
            return "Home"
            
        }
    }
    
}
#if DEBUG

#Preview {
    CaptureProcessHomeView(vmHome: .createOnboarding(configurations: Configurations.mock(), state: .onboarding, completion: {_ in}))
        .environmentObject(LoaderViewModel())
}
#endif
