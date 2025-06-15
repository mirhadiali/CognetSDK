//
//  BiometricLoginResponse.swift
//  CaptureFace
//
//  Created by Hadi Ali on 14/05/2025.
//


struct BiometricLoginResponse: Codable {
    var isSuccess: Bool
    var message: String?
    var uid: String?
    
}
