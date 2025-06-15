//
//  BiometricVerifyRequestModel.swift
//  CaptureFace
//
//  Created by Hadi Ali on 16/05/2025.
//

import Foundation

struct BiometricVerifyRequestModel: Codable {
    let biometricType: BiometricType
    let uid: String
    let base64Image: String
    let biometricSide: String?

    enum CodingKeys: String, CodingKey {
        case biometricType
        case uid
        case base64Image = "base64_Image"
        case biometricSide = "biometric_Side"
    }
}
