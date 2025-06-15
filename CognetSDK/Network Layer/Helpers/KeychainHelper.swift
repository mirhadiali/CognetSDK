//
//  KeychainHelper.swift
//  CaptureFace
//
//  Created by Hadi Ali on 12/05/2025.
//


import Foundation
import Security

import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()
    
    // Subscript for String values
    subscript(account: String, service: String) -> String? {
        get {
            guard let data = read(service: service, account: account) else { return nil }
            return String(data: data, encoding: .utf8)
        }
        set {
            if let newValue = newValue {
                if let data = newValue.data(using: .utf8) {
                    save(data, service: service, account: account)
                }
            } else {
                delete(service: service, account: account)
            }
        }
    }
    
    func save(_ data: Data, service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account,
            kSecValueData as String   : data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne
        ]

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        return status == errSecSuccess ? item as? Data : nil
    }

    func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: USAGE
// Save
//KeychainHelper.shared["accessToken", "com.yourapp.token"] = "abc123"
//
// Retrieve
//let token = KeychainHelper.shared["accessToken", "com.yourapp.token"]
//
// Delete
//KeychainHelper.shared["accessToken", "com.yourapp.token"] = nil
