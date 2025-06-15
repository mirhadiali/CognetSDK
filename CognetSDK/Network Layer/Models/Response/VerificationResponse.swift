//
//  VerificationResponse.swift
//  CaptureFace
//
//  Created by Hadi Ali on 16/05/2025.
//


import Foundation

struct VerificationResponse: Codable {
    var isSuccess: Bool
    var message: String?
    var isVerified: Bool?
    
}


