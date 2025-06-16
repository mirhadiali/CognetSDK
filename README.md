# CognetSDK

A Swift framework for biometric authentication and verification processes.

## Installation

Add the following to your Package.swift:

```swift
.package(url: "https://github.com/mirhadiali/CognetSDK.git", from: "1.0.0")
```

# Usage

### Initialization

```swift
import CognetSDK

CognetSDKManager.shared.initializeSdk(email: String?, password: String?, completion: @escaping (CognetSession?, SDKError?) -> Void)
```

#### What you get!

``` swift
public struct CognetSession {
    public var configuration: Configurations
    public var token: String
    public var sessionId: String
}

public struct SDKError {
    public var message: String
}
```

## Initiate flow
``` swift
CaptureProcessHomeView(vmHome: CaptureProcessHomeViewModel)
```

### OnBoarding Process
Pass this static func to run onboarding

``` swift
public static func createOnboarding(
        configurations: Configurations,
        totalStep: [Steps] = Steps.allCases,
        state: KYCState,
        completion: @escaping (KYCResponse) -> Void
    ) -> CaptureProcessHomeViewModel
```

#### what you get!
``` swift
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
```

#### Example

``` swift
CaptureProcessHomeView(vmHome: .createOnboarding(configurations: configurations, totalStep: configurations.getOnboardingSteps(), state: .onboarding, completion: { response in
    // Handle KYCResponse
 }))
```

### Biometric Process

Pass this static func to run biometric
``` swift
public static func createBiometric(
        biometricData: BiometricData,
        state: KYCState,
        completion: @escaping (IsSuccess, uid?) -> Void
    ) -> CaptureProcessHomeViewModel 
```

#### Example

```swift
CaptureProcessHomeView(vmHome: .createBiometric(biometricData: biometricData, state: .biometric, completion: { isSuccess, uid in
    if isSuccess {
        // Handle success
        // Save uid
    } else {
        // Handle failure
    }
}))
```
where as BiometricData is a model you'll need to pass

``` swift
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
```

### Verification Process

Pass this static func to run verification
``` swift
public static func createVerification(
        configurations: Configurations,
        totalStep: [Steps] = Steps.allCases,
        state: KYCState,
        verificationResponseCompletion: @escaping (isVerified?) -> Void
    ) -> CaptureProcessHomeViewModel
```

#### Example

```swift
CaptureProcessHomeView(vmHome: .createVerification(configurations: configurations,
    totalStep: configurations.getVerificationSteps(), state: .verification, verificationResponseCompletion: { isVerified in
        if let isVerified = isVerified, isVerified {
            // Handle verification success
        } else {
            // Handle verification failure
        }
    }))
```

## Requirements

- iOS 15.5+
- Swift 5.0+

## License

MIT License
