//
//  SDKInitializeResponse.swift
//  CaptureFace
//
//  Created by Hadi Ali on 12/05/2025.
//
import Foundation

struct SDKInitializeResponse: Codable {
    let isSuccess: Bool
    let token: String
    let message: String
    let sessionId: String
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isSuccess = try container.decodeIfPresent(Bool.self, forKey: .isSuccess) ?? false
        self.token = try container.decode(String.self, forKey: .token)
        self.message = try container.decode(String.self, forKey: .message)
        self.sessionId = try container.decode(String.self, forKey: .sessionId)
    }
}
