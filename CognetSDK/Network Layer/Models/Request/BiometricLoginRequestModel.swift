//
//  BiometricLoginRequestModel.swift
//  CaptureFace
//
//  Created by Hadi Ali on 14/05/2025.
//


import Foundation
public enum DocumentNumberType: String, Codable {
    case idcard
    case passport
    case uid
}

struct BiometricLoginRequestModel: Codable {
    let biometricType: BiometricType
    let documentNumber: String
    let documentNumberType: DocumentNumberType
    let mobileNumber: String
    let base64Image: String
    let biometricSide: BiometricSide?

    enum CodingKeys: String, CodingKey {
        case biometricType
        case documentNumber
        case documentNumberType
        case mobileNumber
        case base64Image = "base64_Image"
        case biometricSide = "biometric_Side"
    }
}
