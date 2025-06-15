//
//  IDCardRequest.swift
//  CaptureFace
//
//  Created by Hadi Ali on 21/04/2025.
//
import Foundation

struct IDCardRequest: Encodable {
    let base64_1: String
    let base64_2: String
    
    enum CodingKeys: String, CodingKey {
        case base64_1 = "base64_Front"
        case base64_2 = "base64_Back"
    }
}
