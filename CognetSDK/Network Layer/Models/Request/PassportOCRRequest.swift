//
//  PassportOCRRequest.swift
//  CaptureFace
//
//  Created by Hadi Ali on 20/04/2025.
//

import Foundation

struct PassportOCRRequest: Encodable {
    let base64: String
    
    enum CodingKeys: String, CodingKey {
        case base64 = "base64_Main"
    }
}

