


import SwiftUI

struct DocumentScanView: View {
    
    @ObservedObject var vmHome:CaptureProcessHomeViewModel
    @State private var showDatePicker = false
    var action:()->Void
    var captureType:CaptureType = .document
    @StateObject var cameraModel = CameraModel(type: .document)
    @State private var isScaled = false
    
    var body: some View {
        ZStack{
            VStack(alignment: .center, spacing: 16) {
                // Step Indicator
                topView
                if vmHome.documentType == .passport {
                    passportView
                } else {
                    idCardView
                }
                Spacer()
            }
            .padding([.all],5)
            .frame(height: UIScreen.main.bounds.height - 150)
            .background(
                // GradientBackground()
                ThemeManager.color(.white).opacity(0.1)
                    .cornerRadius(20)
                //                RoundedRectangle(cornerRadius: 20)
                //                    .fill(ThemeManager.color(.white)) // Translucent background
            )
            .onReceive(vmHome.$readPassportNFC, perform: { newValue in
                if newValue {
                    vmHome.startNfcFlow()
                } else {
                    vmHome.nfcStatus = .inprogress
                }
            })
            .commonAlert(isPresented: $vmHome.showErrorAlert, alert: AlertViewModel(alertTitle: "Error",alertMessage: vmHome.errorMessage))
            
        }
    }
    
    var nfcBottomButtons: some View {
        HStack(spacing: 12) {
            // Skip Button
            Button(action: {
                // Skip NFC action
                vmHome.readPassportNFC = false
                action()
            }) {
                HStack {
                    Image(systemName: "square.grid.2x2")
                        .foregroundColor(.white)
                    Text("Skip NFC Verification")
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: 1)
                )
            }
            
            // Retry Button
            Button(action: {
                // Retry NFC action
                vmHome.readPassportNFC = true
            }) {
                Text("Retry")
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                    .font(.system(size: 14))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
//        .padding()
    }
    
    var topView: some View {
        VStack(alignment: .center, spacing: 16) {
//            if vmHome.progressStep.rawValue > 0 {
//                HStack{
//                    Text("Step 1/\(vmHome.totalStep.count-1)")
//                        .font(FontManager.customFont(.bold, size: .small))
//                        .foregroundColor(ThemeManager.color(.text))
//                        .padding(.top)
//                    Spacer()
//                }
//                .padding(.horizontal)
//                
//            }
            
            // Progress Bar
            if vmHome.progressStep.rawValue > 0 {
                
                ProgressView(value: Float(vmHome.progressStep.rawValue)/Float(vmHome.totalStep.count)) // 20% Progress for Step 1 of 5
                    .progressViewStyle(LinearProgressViewStyle(tint: ThemeManager.color(.secondary)))
                    .frame(height: 4)
                    .background(ThemeManager.color(.white).opacity(0.7))
                    .cornerRadius(2)
                    .padding(.horizontal)
                
            }
//            if vmHome.docImage == nil, vmHome.frontId == nil, vmHome.backId == nil {
//                DocumentToggleView(selected: $vmHome.documentType)
//            }
            HStack(alignment: .center){
                // Instruction Text
                Image(vmHome.readPassportNFC ? .nfc : .card)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color("icon1"))
                    .frame(width: 50, height: 50)
                VStack(alignment:.leading){
                    Text("Scan \(vmHome.documentType.getTitle())")
                        .font(FontManager.customFont(.bold, size: .medium))
                        .foregroundColor(ThemeManager.color(.text))
                    Text(vmHome.readPassportNFC ? "Bring your passport close to the phone" : "Make sure to place the \(vmHome.documentType.getTitle()) on a flat surface")
                        .font(FontManager.customFont(.regular, size: .normal))
                        .foregroundColor(ThemeManager.color(.text))
                }
                Spacer()
            }.padding(.top)
                .padding(.horizontal)
            Divider()
                .frame(height: 1)
                .background(ThemeManager.color(.text))
                .padding(.horizontal)
        }
    }
    
    var cardScaleAnimationView: some View {
        VStack{
            Image("card")
                .resizable()
                .scaledToFit()
                .padding()
                .foregroundColor(ThemeManager.color(.white))
                .scaleEffect(isScaled ? 1.0 : 0.3) // Scale effect
                .animation(.easeInOut(duration: 2.0), value: isScaled)                                .onAppear(perform: {
                    isScaled = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation{
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
        }.padding(.horizontal)
    }
    var cameraView: some View {
        ZStack{
            DocumentScannerView(capturedImage: $vmHome.docImage,
                                documentType: .passport,
                                onCapture: { image in
                withAnimation{
                    vmHome.showedSuccessImage = false
                    vmHome.docImage = image
                }
            })
            .frame(height: 300)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(style: StrokeStyle(lineWidth: 3, dash: [10]))
                    .foregroundColor(.white)
                
            )
            .shadow(radius: 5)
            .padding(.top,50)
            
//            CameraView(cameraModel: cameraModel ,action: { image in
//                withAnimation{
//                    vmHome.showedSuccessImage = false
//                    
//                    vmHome.docImage = image
//                }
//            }, reloadManager: ReloadManager()).transition(.opacity).padding(.top,50)
        }
    }
    
    var passportView: some View {
        VStack(alignment: .center, spacing: 16) {
            if let imageData = vmHome.docImage{
                if vmHome.showedSuccessImage == false{
                    //                        GIFPlayerView(gifName: "successTick")
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
                    
                    if vmHome.readPassportNFC {
                        VStack{
#if DEBUG
                            VStack {
                                Text("Locally generated MRZ Key = \(vmHome.ocrKey)")
                                Text("Copy the data \n\(vmHome.scannedKey)")
                                    .lineLimit(nil)
                                    .textSelection(.enabled)
                            }
                            .font(.system(size: 10))
                            .foregroundStyle(.white)
#endif
                            Spacer()
                            Image(.nfc)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(Color("icon1"))
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200, height: 200)
                            
                            Spacer()
                            switch vmHome.nfcStatus {
                            case .success:
                                PrimaryButton(isLoading: vmHome.showLoader, title: vmHome.getButtonTitle, action: {
                                    action()
                                })
                            case .failed:
                                nfcBottomButtons
                            case .inprogress:
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                            }
                            
                        }.padding(.horizontal)
                    } else {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: imageData)
                                .resizable()
                                .scaledToFit()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: vmHome.getHeight(captureType: captureType))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            Button(action: {
                                vmHome.showedLoaderImage = false
                                isScaled = false
                                
                                vmHome.docImage = nil // Remove image
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(ThemeManager.color(.secondary))
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .padding(5)
                            }
                        }.transition(.opacity)
                            .padding(.horizontal)
                            .disabled(vmHome.showLoader)
                        PrimaryButton(isLoading: vmHome.showLoader, title: vmHome.getButtonTitle, action: {
                            vmHome.showedLoaderImage = false
                            vmHome.uploadPassportToOCR {
                                if CognetSDKManager.shared.isNFCAllowed {
                                    vmHome.readPassportNFC = true
                                } else {
                                    action()
                                }
                            }
                            
                        }).padding()
                    }
                }
            }else{
                if vmHome.showedLoaderImage == false{
                    cardScaleAnimationView
                    
                }else{
                    cameraView
                }
            }
        }
        .onChange(of: vmHome.tempImage) { newImage in
            guard let image = newImage, vmHome.documentType == .passport else { return }
            
            if vmHome.docImage == nil {
                vmHome.docImage = image
            }
            
            // Reset camera image to avoid repeated setting
            vmHome.tempImage = nil
        }
    }
   
    var idCardView: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                Text(vmHome.frontId == nil ? "Capture Front of ID Card" : vmHome.backId == nil ? "Capture Back of ID Card" : "Review ID Card Images")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack {
                    
                    if vmHome.frontId == nil || vmHome.backId == nil, vmHome.showedSuccessImage {
                        
                        DocumentScannerView(capturedImage: $vmHome.tempImage,
                                            documentType: .idCard,
                                            onCapture: { image in
                            withAnimation{
                                vmHome.showedSuccessImage = false
                                vmHome.tempImage = image
                            }
                        })
                        .frame(height: vmHome.getHeight(captureType: captureType))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(style: StrokeStyle(lineWidth: 3, dash: [10]))
                                .foregroundColor(.white)
                            
                        )
                        .shadow(radius: 5)
                        .padding(.top,50)
                    }
                    if vmHome.showedSuccessImage == false{
                        SuccessTickView()
                            .padding(.top,40)
                            .onAppear(perform: {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    withAnimation{
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                            vmHome.showedSuccessImage = true
                                        }
                                    }
                                }
                            }).transition(.opacity)
                        
                        
                    }
                    
                    if let frontImage = vmHome.frontId {
                        
                        ZStack (alignment: .topTrailing){
                            Image(uiImage: frontImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(10)
                                .overlay(Text("Front Side").foregroundColor(.white).padding(4), alignment: .bottomTrailing)
                            Button(action: {
                                
                                vmHome.frontId = nil // Remove image
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
                    }
                    
                    if let backImage = vmHome.backId {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: backImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(10)
                                .overlay(Text("Back Side").foregroundColor(.white).padding(4), alignment: .bottomTrailing)
                            Button(action: {
                                
                                vmHome.backId = nil // Remove image
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
                    }
                }
                
                // Continue Button
                if vmHome.frontId != nil && vmHome.backId != nil {
                    PrimaryButton(isLoading: vmHome.showLoader, title: "Continue", action: {
                        
                        vmHome.uploadIDCardsToOCR {
                            action()
                        }
                    })
                }
            }
            .disabled(vmHome.showLoader)
        }
        .onChange(of: vmHome.tempImage) { newImage in
            guard let image = newImage, vmHome.documentType == .idCard else { return }
            
            if vmHome.frontId == nil {
                vmHome.frontId = image
            } else if vmHome.backId == nil {
                vmHome.backId = image
            }
            
            // Reset camera image to avoid repeated setting
            vmHome.tempImage = nil
        }
        .padding()
    }
    
}


#if DEBUG
#Preview {
    DocumentScanView(vmHome: CaptureProcessHomeViewModel(configurations: Configurations.mock(), biometricData: nil, state: .onboarding, completion: {_ in}, biometricResponseCompletion: {_,_ in}, verificationResponseCompletion: {_ in}), action: {
        
    })
    .background {
        BackgroundImageView(imageName: "Bg")
    }
}
#endif
