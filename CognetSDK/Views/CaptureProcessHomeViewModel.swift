

import SwiftUI
import NFCPassportReader


public typealias uid = String
public typealias IsSuccess = Bool
public typealias isVerified = Bool


public enum Steps: Int, CaseIterable, Equatable {
    case info = 0
//    case document
    case passport
    case idcard
    case face
    case faceHand
    case hand
    case complete
}

enum NFStatus: String {
    case success
    case failed
    case inprogress
}

public enum KYCState: String {
    case onboarding
    case verification
    case biometric
}

public struct KYCResponse {
    public let isFaceExist: Bool
    public let isPalmExist: Bool
    public let face_Base64: String?
    public let palm_Base64: String?
    public let palm_Biometric_Side: String?
    public let passportResponseDTO: PassportResult?
    public let idCardResponseDTO: IDCardResult?
    public var uid: String?
    
}

public enum BiometricSide: String, Codable {
    case right
    case left
}

public struct BiometricData: Identifiable {
    public var id = UUID()
    public let documentNumber: String
    public let mobileNumber: String
    public let documentType: DocumentNumberType
    public let biometricType: BiometricType
    public let biometricSide: BiometricSide?
    
    public init(id: UUID = UUID(), documentNumber: String, mobileNumber: String, documentType: DocumentNumberType, biometricType: BiometricType, biometricSide: BiometricSide?) {
        self.id = id
        self.documentNumber = documentNumber
        self.mobileNumber = mobileNumber
        self.documentType = documentType
        self.biometricType = biometricType
        self.biometricSide = biometricSide
    }
}

public class CaptureProcessHomeViewModel: ObservableObject {
    @Published var showLoader: Bool = false
    @Published var showToast: Bool = false
    @Published var toastData: ToastModel? = nil
    @Published var showedLoaderImage: Bool = false
    @Published var showedSuccessImage: Bool = true
    @Published var showedconfirm: Bool = false
    
    @Published var progressStep: Steps = .info
    @Published var totalStep: [Steps] = Steps.allCases
    @Published var docImage: UIImage?
    @Published var frontId: UIImage?
    @Published var backId: UIImage?
    @Published var tempImage: UIImage?
    @Published var faceImage: UIImage?
    @Published var handImage: UIImage?
    @Published var handSide: handSide?
    @Published var faceHandImage: UIImage?

    // NFC Properties
    @Published var readPassportNFC: Bool = false
    @Published var nfcStatus: NFStatus = .inprogress

    private let documentRepository: DocumentRepositoryProtocol
    private let faceHandRepository: FaceHandRepositoryProtocol

    var ocrResponse: PassportOCRResponse?
    var passportReader = PassportReader()
    var idCardResponse: IDCardResponse?

    var documentPortrait: String?

    var uid: String?
    var isFaceExist: Bool = false
    var isPalmExist: Bool = false

    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String = ""

    @Published var ocrKey: String = ""
    @Published var scannedKey: String = ""

    @Published var documentType: DocumentType = .passport

    var state: KYCState
    var configurations: Configurations? = nil
    var responseCompletion: (KYCResponse) -> Void
    var biometricResponseCompletion: (IsSuccess, uid?) -> Void
    var verificationResponseCompletion: (isVerified?) -> Void

    var biometricData: BiometricData?

    // Keep init internal
    init(documentRepository: DocumentRepositoryProtocol = DocumentRepository(),
         faceHandRepository: FaceHandRepositoryProtocol = FaceHandRepository(),
         configurations: Configurations?,
         biometricData: BiometricData?,
         totalStep: [Steps] = Steps.allCases,
         state: KYCState,
         completion: @escaping (KYCResponse) -> Void,
         biometricResponseCompletion: @escaping (IsSuccess, uid?) -> Void,
         verificationResponseCompletion: @escaping (isVerified?) -> Void) {
        self.documentRepository = documentRepository
        self.faceHandRepository = faceHandRepository
        self.state = state
        self.configurations = configurations
        self.totalStep = totalStep
        self.progressStep = totalStep.first ?? .info
        self.responseCompletion = completion
        self.biometricData = biometricData
        self.biometricResponseCompletion = biometricResponseCompletion
        self.verificationResponseCompletion = verificationResponseCompletion
        if self.totalStep.contains(.passport) {
            self.documentType = .passport
        } else {
            self.documentType = .idCard
        }
    }

    // ✅ Only static methods exposed publicly
    public static func createOnboarding(
        configurations: Configurations,
        totalStep: [Steps] = Steps.allCases,
        state: KYCState,
        completion: @escaping (KYCResponse) -> Void
    ) -> CaptureProcessHomeViewModel {
        return CaptureProcessHomeViewModel(
            configurations: configurations,
            biometricData: nil,
            totalStep: totalStep,
            state: state,
            completion: completion,
            biometricResponseCompletion: { (_, _) in },
            verificationResponseCompletion: { _ in }
        )
    }

    public static func createVerification(
        configurations: Configurations,
        totalStep: [Steps] = Steps.allCases,
        state: KYCState,
        verificationResponseCompletion: @escaping (isVerified?) -> Void
    ) -> CaptureProcessHomeViewModel {
        return CaptureProcessHomeViewModel(
            configurations: configurations,
            biometricData: nil,
            totalStep: totalStep,
            state: state,
            completion: { _ in },
            biometricResponseCompletion: { (_, _) in },
            verificationResponseCompletion: verificationResponseCompletion
        )
    }

    public static func createBiometric(
        biometricData: BiometricData,
        state: KYCState,
        completion: @escaping (IsSuccess, uid?) -> Void
    ) -> CaptureProcessHomeViewModel {
        let steps: [Steps] = biometricData.biometricType == .face ? [.face] : [.hand]

        return CaptureProcessHomeViewModel(
            configurations: nil,
            biometricData: biometricData,
            totalStep: steps,
            state: state,
            completion: { _ in },
            biometricResponseCompletion: completion,
            verificationResponseCompletion: { _ in }
        )
    }
    
    private func prepareSteps() {
        guard let configs = CognetSDKManager.shared.configurations else {
            return
        }
        self.configurations = configs
        
        switch state {
        case .onboarding:
            self.totalStep = configs.getOnboardingSteps()
            if configs.onboardingFlow.documentEngine.idCard {
                documentType = .idCard
            }
            if configs.onboardingFlow.documentEngine.passport {
                documentType = .passport
            }
        case .verification, .biometric:
            self.totalStep = configs.getVerificationSteps()
        }
        self.progressStep = totalStep.first ?? .info
    }
    
    var getButtonTitle: String{
        switch self.progressStep{
        case .info:
            return "Continue"
        case .idcard, .passport:
            return "Continue"
        case .face:
            return "Continue"
        case .faceHand:
            return "Continue"
        case .hand:
            return "Continue"
        case .complete:
            return "Proceed"
        default:
            return "Continue"

        }
    }
    
    func getHeight(captureType:CaptureType)->CGFloat{
        switch captureType {
        
        case .document:
            return 200
        case .face:
            return 380
        case .hand:
            return 380

        case .faceHand:
            return 380

        }
    }
    
    func previousStep() {
        if let currentIndex = totalStep.firstIndex(of: progressStep),
           currentIndex > 0 {
            progressStep = totalStep[currentIndex - 1]
        }
    }
    
    func nextStep() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let currentIndex = totalStep.firstIndex(of: progressStep),
               currentIndex < totalStep.count - 1 {
                progressStep = totalStep[currentIndex + 1]
            }
        }
    }
    
    func uploadPassportToOCR(succesCompletion: @escaping ()->Void) {
        guard let image = docImage else {
            errorMessage = "No passport image found"
            showErrorAlert = true
            return
        }

        showLoader = true

        Task {
            let result = await documentRepository.verifyPassport(image: image)

           await MainActor.run {
                self.showLoader = false

                switch result {
                case .success(let response):
                    
#if DEBUG
                    self.verifyDocument(image1: image, portrait: response.result.images.portrait) {
                        self.ocrResponse = response
                        self.documentPortrait = response.result.images.portrait
                        self.toastData = ToastModel(message: "✅ Passport verified", duration: 1, code: .success)
                        self.showToast = true
                        succesCompletion()
                        
                    }
                    return
#endif
                    if response.result.mrz.isExpired() {
                        self.showErrorAlert = true
                        self.errorMessage = "This passport is expired"
                    } else {
                        self.verifyDocument(image1: image, portrait: response.result.images.portrait) {
                            self.ocrResponse = response
                            self.documentPortrait = response.result.images.portrait
                            self.toastData = ToastModel(message: "✅ Passport verified", duration: 1, code: .success)
                            self.showToast = true
                            succesCompletion()
                        }
                        
                    }

                    
                case .failure(let error):
                    print(error.localizedDescription)
                    self.errorMessage = "Please scan the document again."
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    func uploadIDCardsToOCR(succesCompletion: @escaping ()->Void) {
        guard let frontImage = frontId, let backImage = backId else {
            errorMessage = "No passport image found"
            showErrorAlert = true
            return
        }

        showLoader = true

        Task {
            let result = await documentRepository.verifyIDCard(frontID: frontImage, backID: backImage)

            DispatchQueue.main.async {
                self.showLoader = false

                switch result {
                case .success(let response):
                    
                    if response.result.isExpired() {
                        self.showErrorAlert = true
                        self.errorMessage = "This ID card is expired"
                    } else {
                        
                        self.verifyDocument(image1: frontImage, portrait: response.result.images.portrait) {
                            self.idCardResponse = response
                            self.documentPortrait = response.result.images.portrait
                            self.toastData = ToastModel(message: "✅ ID Card verified", duration: 1, code: .success)
                            self.showToast = true
                            succesCompletion()
                        }
                       
                    }
                    
                case .failure(let error):
                    print(error.localizedDescription)
                    self.errorMessage = "Please scan the document again."
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    func verifyDocument(image1: UIImage, portrait: String?, succesCompletion: @escaping ()->Void) {
        showLoader = true
        guard let image1Portrait = image1.imageToBase64(),
              let image2Portrait = portrait
        else {
            errorMessage = "No face image found"
            showErrorAlert = true
            return
        }
        
        Task {
            let result = await faceHandRepository.faceVerify(face1: image1Portrait, face2: image2Portrait)
            
            await MainActor.run {
                 self.showLoader = false

                 switch result {
                 case .success(let response):
                     if let isVerified = response.isVerified, isVerified {
                         succesCompletion()
                         
                     } else {
                         errorMessage = "Face not verified"
                         showErrorAlert = true
                     }
                 case .failure(let error):
                     print(error.localizedDescription)
                     switch error {
                     case .apiError(let message, let details):
                         self.errorMessage = details ?? "Please try again"
                     default:
                         self.errorMessage = "Please try again"
                     }
                     self.showErrorAlert = true
                 }
             }
        }
    }
    
    func startNfcFlow() {
        
        // Start NFC scanning
        scanPassportNFC()
    }
    
    func scanPassportNFC() {
        self.nfcStatus = .inprogress
        startNfcScan() { success in
            DispatchQueue.main.async {
                if success {
                    
                    self.showedSuccessImage = false
                    self.nfcStatus = .success
                    self.toastData = ToastModel(message: "✅ Passport validated", duration: 3, code: .success)
                    self.showToast = true
                } else {
                    self.nfcStatus = .failed
                }
            }
        }
    }
    
    func resetNFC() {
        nfcStatus = .inprogress
        readPassportNFC = false
    }
    
    func startNfcScan(completion: @escaping (Bool) -> Void) {
        guard let ocr = ocrResponse else {
            completion(false)
            return
        }
       
        // 1. Generate MRZ Key from OCR
        let mrzKey = ocr.result.mrz.generateMRZKey()
        self.ocrKey = mrzKey
        // 2. Optional: Set master list and verification method
        // Set the masterListURL on the Passport Reader to allow auto passport verification
        if let masterListURL = Bundle.main.url(forResource: "masterList", withExtension: "pem") {
            passportReader.setMasterListURL(masterListURL)
        }
        // Set whether to use the new Passive Authentication verification method (default true) or the old OpenSSL CMS verifiction
        passportReader.passiveAuthenticationUsesOpenSSL = true // or true based on your setting

        // 3. Custom display messages (optional)
        let customMessageHandler: (NFCViewDisplayMessage) -> String? = { displayMessage in
            switch displayMessage {
            case .requestPresentPassport:
                return "Hold your iPhone near your passport to begin scanning."
            default:
                return nil
            }
        }
        // 4. Read the passport via NFC
        
        Task {
            do {
                let passport = try await passportReader.readPassport(
                    mrzKey: mrzKey,
                    tags: DataGroupId.allCases,
                    customDisplayMessage: customMessageHandler
                )
                
                // Dump passport data to a dictionary
                let dict = passport.dumpPassportData(
                    selectedDataGroups: DataGroupId.allCases,
                    includeActiveAuthenticationData: true
                )
                // Convert dict to JSON String
                let jsonString: String
                if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
                   let json = String(data: jsonData, encoding: .utf8) {
                    jsonString = json
                } else {
                    jsonString = "⚠️ Failed to convert passport data to JSON"
                }
                
                // 5. Get the MRZ string from DG1 (MachineReadableZone)
                let mrzFromChip = passport.passportMRZ
                    .replacingOccurrences(of: "\n", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                let expectedMRZ = ocr.result.mrz.mrzCode
                    .replacingOccurrences(of: "\n", with: "")
                    .replacingOccurrences(of: ",", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                let isValid = mrzFromChip == expectedMRZ
                
                await  MainActor.run {
                    self.scannedKey = """
                             ✅ Passport MRZ verified: \(isValid ? "MATCH ✅" : "MISMATCH ❌")
                             
                             MRZ From Chip: \(mrzFromChip)
                             MRZ From OCR:  \(expectedMRZ)
                             
                             Passport Data:
                             \(jsonString)
                             """
                }
                
                DispatchQueue.main.async {
                    completion(isValid)
                }
            } catch {
                print("NFC scan failed:", error.localizedDescription)
                await  MainActor.run { [weak self] in
                    self?.errorMessage = error.localizedDescription
                    self?.showErrorAlert = true
                    
                    self?.nfcStatus = .failed
                    completion(false)
                }
            }
        }
    }
    
    func returnResponse(action: () -> Void) {
        responseCompletion(.init(isFaceExist: isFaceExist,
                                 isPalmExist: isPalmExist,
                                 face_Base64: faceImage?.imageToBase64(),
                                 palm_Base64: handImage?.imageToBase64(),
                                 palm_Biometric_Side: handSide,
                                 passportResponseDTO: ocrResponse?.result,
                                 idCardResponseDTO: idCardResponse?.result,
                                 uid: uid))
        action()
    }
    
}

extension CaptureProcessHomeViewModel {
    func checkLiveness(succesCompletion: @escaping ()->Void) {
        guard let image = faceImage else {
            errorMessage = "No face image found"
            showErrorAlert = true
            return
        }

        showLoader = true

        Task {
            let result = await faceHandRepository.checkLiveness(faceImage: image)

           await MainActor.run {
                self.showLoader = false

                switch result {
                case .success(let response):
                    if response.isReal {
                        self.showLoader = true
                        switch state {
                        case .verification:
                            self.biometricVerify(image: image, succesCompletion: succesCompletion)
                        case .biometric:
                            self.biometricLogin(image: image, succesCompletion: succesCompletion)
                        case .onboarding:
                            self.faceVerifyAndSearch(faceImage: image, succesCompletion: succesCompletion)
                        }
                       
                    } else {
                        switch state {
                        case .biometric:
                            biometricResponseCompletion(false, nil)
                            succesCompletion()
                        case .verification, .onboarding:
                            self.showErrorAlert = true
                            self.errorMessage = "Please scan again."
                        }
                    }
                    
                case .failure(let error):
                    print(error.localizedDescription)
                    self.errorMessage = "Please scan the face again."
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    func handBiometricLogin(succesCompletion: @escaping ()->Void) {
        if let handImage = self.handImage {
            biometricLogin(image: handImage, succesCompletion: succesCompletion)
        } else {
            errorMessage = "Can't detect hand"
            showErrorAlert = true
        }
    }
    
    private func biometricLogin(image: UIImage, succesCompletion: @escaping ()->Void) {
        guard let base64Image = image.imageToBase64(), let biometricData = self.biometricData else {
            self.showLoader = false
            return
        }
        let request: BiometricLoginRequestModel = .init(biometricType: biometricData.biometricType,
                                                        documentNumber: biometricData.documentNumber,
                                                        documentNumberType: biometricData.documentType,
                                                        mobileNumber: biometricData.mobileNumber,
                                                        base64Image: base64Image,
                                                        biometricSide: biometricData.biometricSide)
        
        Task {
            let result = await faceHandRepository.biometricLogin(request: request)
            
            await MainActor.run {
                 self.showLoader = false

                 switch result {
                 case .success(let response):
                     if let uid = response.uid {
                         self.uid = uid
                         self.biometricResponseCompletion(true, uid)
                         self.isFaceExist = true
                         
                     } else {
                         self.isFaceExist = false
                         self.biometricResponseCompletion(false, nil)
                     }
                     succesCompletion()
                     
                 case .failure(let error):
                     print(error.localizedDescription)
                     switch error {
                     case .apiError(let message, let details):
                         self.errorMessage = details ?? "Please try again"
                     default:
                         self.errorMessage = "Please try again"
                     }
                     self.showErrorAlert = true
                 }
             }
        }
    }
    
    func biometricVerify(image: UIImage?, succesCompletion: @escaping ()->Void) {
        guard let base64Image = image?.imageToBase64() else {
            self.showLoader = false
            return
        }
        guard let configs = configurations, let uid = CognetSDKManager.shared.uid else {
            self.showErrorAlert = true
            self.errorMessage = "Couldn't proceed"
            return
        }
        let request: BiometricVerifyRequestModel = .init(biometricType: configs.verificationFlow.faceEngine ? .face : .palm,
                                                         uid: uid,
                                                         base64Image: base64Image,
                                                         biometricSide: handSide)
        
        Task {
            let result = await faceHandRepository.biometricVerify(request: request)
            
            await MainActor.run {
                 self.showLoader = false

                 switch result {
                 case .success(let response):
                     if let isVerified = response.isVerified {
                         self.verificationResponseCompletion(isVerified)
                         
                     } else {
                         self.verificationResponseCompletion(nil)
                         self.biometricResponseCompletion(false, nil)
                     }
                     succesCompletion()
                     
                 case .failure(let error):
                     print(error.localizedDescription)
                     switch error {
                     case .apiError(let message, let details):
                         self.errorMessage = details ?? "Please try again"
                     default:
                         self.errorMessage = "Please try again"
                     }
                     self.showErrorAlert = true
                 }
             }
        }
    }
    
    func faceVerifyAndSearch(faceImage: UIImage, succesCompletion: @escaping ()->Void) {
        guard let portrait = self.documentPortrait else {
            self.showLoader = false
            return
        }
        Task {
            let result = await faceHandRepository.faceVerifyAndSearch(documentImage: portrait, faceImage: faceImage)
            
            await MainActor.run {
                 self.showLoader = false

                 switch result {
                 case .success(let response):
                     if let uid = response.uid {
                         self.uid = uid
                         self.isFaceExist = true
                         
                     } else {
                         self.isFaceExist = false
                     }
                     succesCompletion()
                     
                 case .failure(let error):
                     print(error.localizedDescription)
                     switch error {
                     case .apiError(let message, let details):
                         self.errorMessage = details ?? "Please try again"
                     default:
                         self.errorMessage = "Please try again"
                     }
                     self.showErrorAlert = true
                 }
             }
        }
    }
    
    func scanFaceWithHand(succesCompletion: @escaping ()->Void) {
        if totalStep.contains(.face) {
            faceVerify(succesCompletion: succesCompletion)
        } else {
            checkOnlyHandFaceLiveness(succesCompletion: succesCompletion)
        }
    }
    
    func faceVerify(succesCompletion: @escaping ()->Void) {
        
        guard let face1 = self.faceImage?.imageToBase64() else {
            succesCompletion()
            return
        }
        guard let face2 = self.faceHandImage?.imageToBase64()
        else {
            errorMessage = "No face found"
            showErrorAlert = true
            return
        }
        showLoader = true
        Task {
            let result = await faceHandRepository.faceVerify(face1: face1, face2: face2)
            
            await MainActor.run {
                 self.showLoader = false

                 switch result {
                 case .success(let response):
                     if let isVerified = response.isVerified, isVerified {
                         succesCompletion()
                         
                     } else {
                         errorMessage = "Face not verified"
                         showErrorAlert = true
                     }
                 case .failure(let error):
                     print(error.localizedDescription)
                     switch error {
                     case .apiError(let message, let details):
                         self.errorMessage = details ?? "Please try again"
                     default:
                         self.errorMessage = "Please try again"
                     }
                     self.showErrorAlert = true
                 }
             }
        }
    }
    
    func checkOnlyHandFaceLiveness(succesCompletion: @escaping ()->Void) {
        guard let image = faceHandImage else {
            errorMessage = "No face image found"
            showErrorAlert = true
            return
        }

        showLoader = true

        Task {
            let result = await faceHandRepository.checkLiveness(faceImage: image)

           await MainActor.run {
                self.showLoader = false

                switch result {
                case .success(let response):
                    if response.isReal {
                        self.showLoader = true
                        
                        self.faceVerifyAndSearch(faceImage: image, succesCompletion: succesCompletion)
                        
                       
                    } else {
                        self.showErrorAlert = true
                        self.errorMessage = "Please scan again."
                    }
                    
                case .failure(let error):
                    print(error.localizedDescription)
                    self.errorMessage = "Please scan the face again."
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    func handVerifyAndSearch(succesCompletion: @escaping ()->Void) {
        showLoader = true
        guard let hand1 = self.faceHandImage,
              let hand2 = self.handImage
        else {
            errorMessage = "No face image found"
            showErrorAlert = true
            return
        }
        
        guard let portrait = self.documentPortrait else {
            self.showLoader = false
            return
        }
        Task {
            let result = await faceHandRepository.handVerifyAndSearch(hand1: hand1, hand2: hand2)
            
            await MainActor.run {
                 self.showLoader = false

                 switch result {
                 case .success(let response):
                     if let uid = response.uid {
                         if isFaceExist, self.uid == uid {
                             self.uid = uid
                         } else if isFaceExist, self.uid != uid {
                             self.errorMessage = "Hand does not match with face. Please retry"
                             self.showErrorAlert = true
                             return
                         }
                         self.isPalmExist = true
                         self.uid = uid
                     } else {
                         self.isPalmExist = false
                     }
                     succesCompletion()
                 case .failure(let error):
                     print(error.localizedDescription)
                     switch error {
                     case .apiError(let message, let details):
                         self.errorMessage = details ?? "Please try again"
                     default:
                         self.errorMessage = "Please try again"
                     }
                     self.showErrorAlert = true
                 }
             }
        }
    }
}
