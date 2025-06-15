//
//  VerifyAndSearchRequest.swift
//  CaptureFace
//
//  Created by Hadi Ali on 13/05/2025.
//

import Foundation

public enum BiometricType: String, Codable {
    case palm
    case face
}

struct VerifyAndSearchRequest: Codable {
    let biometricType: BiometricType
    let image_1: String
    let image_2: String
    var isPortrait: Bool
    
}
