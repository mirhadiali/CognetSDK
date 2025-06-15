//
//  VerifyFaceResponse.swift
//  CaptureFace
//
//  Created by Hadi Ali on 13/05/2025.
//


import Foundation

struct VerifyFaceResponse: Codable {
    var isSuccess: Bool
    var message: String?
    var isVerified: Bool?
    
}


