//
//  PlistKey.swift
//  cognetSDK
//
//  Created by Hadi Ali on 26/05/2025.
//


import Foundation

enum PlistKey: String {
    case baseURL = "Base URL"

    private var infoDictionary: [String: Any] {
        if let dictionary = Bundle.main.infoDictionary {
            return dictionary
        } else {
            fatalError("Relevant .plist file not found")
        }
    }

    func value() -> String {
        guard let value = infoDictionary[self.rawValue] as? String else {
            return ""
        }
        return value
    }
}
