//
//  APIHeader.swift
//  cognetSDK
//
//  Created by Hadi Ali on 26/05/2025.
//



import Foundation
import UIKit

public class APIHeader {

    static let shared = APIHeader()
    private var token: String?
    private var sessionID: String?
    
    private init() { }
    
    func initializeSDKHeaders() -> [String: String] {
        var headers: [String: String] = [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Channel-Id": "1"
        ]
        if let uid = UIDevice.current.identifierForVendor?.uuidString {
            headers["Mac-Address"] = uid
        }
        return headers
    }

    public func getHeader() -> [String: String] {
        var headers: [String: String] = [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Channel-Id": "1"
        ]
        
//        if let token = KeychainHelper.shared["accessToken", "com.kycapp.token"],
//           let sessionId = KeychainHelper.shared["sessionId", "com.kycapp.sessionid"] {
        if let token = token,
           let sessionId = sessionID {
            
            headers["token"] = token
            headers["Session-Id"] = sessionId
            
        }
        if let uid = UIDevice.current.identifierForVendor?.uuidString {
            headers["Mac-Address"] = uid
        }
        return headers
    }
    
    func updateHeaders(initResponse: SDKInitializeResponse) {
        token = initResponse.token
        sessionID = initResponse.sessionId
//        KeychainHelper.shared["accessToken", "com.kycapp.token"] = initResponse.token
//        KeychainHelper.shared["sessionId", "com.kycapp.sessionid"] = initResponse.sessionId
    }
}
