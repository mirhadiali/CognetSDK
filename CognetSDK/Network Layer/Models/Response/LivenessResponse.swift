//
//  LivenessResponse.swift
//  CaptureFace
//
//  Created by Hadi Ali on 13/05/2025.
//

import Foundation

struct LivenessResponse: Codable {
    let isSuccess: Bool
    let message: String?
    let isReal: Bool
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isSuccess = try container.decodeIfPresent(Bool.self, forKey: .isSuccess) ?? false
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
        self.isReal = try container.decode(Bool.self, forKey: .isReal)
    }
}


