# CognetSDK

A Swift framework for biometric authentication and verification processes.

## Installation

Add the following to your Package.swift:

```swift
.package(url: "https://github.com/mirhadiali/CognetSDK.git", from: "1.0.0")
```

## Usage

### Initialization

```swift
CognetSDKManager.shared.initializeSdk() { configurations, errorMessage in
    if let configs = configurations {
        // Use configurations
    }
}
```

### Biometric Process

```swift
CaptureProcessHomeView(vmHome: .createBiometric(biometricData: biometricData, state: .biometric, completion: { isSuccess, uid in
    if isSuccess {
        // Handle success
    } else {
        // Handle failure
    }
}))
```

### Verification Process

```swift
CaptureProcessHomeView(vmHome: .createVerification(configurations: configs,
    totalStep: configs.getVerificationSteps(), state: .verification, verificationResponseCompletion: { isVerified in
        if let isVerified = isVerified, isVerified {
            // Handle verification success
        } else {
            // Handle verification failure
        }
    }))
```

## Requirements

- iOS 13.0+
- Swift 5.0+

## License

MIT License
