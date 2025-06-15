
//
//  CognetSDKManager.swift
//  CaptureFace
//
//  Created by Hadi Ali on 27/04/2025.
//

import Foundation
public struct CognetSession {
    public var configuration: Configurations
    public var token: String
    public var sessionId: String
}

public struct SDKError {
    public var message: String
}

public class CognetSDKManager: ObservableObject {
    private let sdkRepository: SDKRepositoryProtocol
    public static let shared = CognetSDKManager()
    
    @Published public var uid: String? //= "kkeffseufa0sp8u30mhyg4os"
    
    var isNFCAllowed: Bool = true
    var configurations: Configurations?
    var sessionTime: Date = Date()
    var sessionTimeOutInterval: Int = 1
    var email = ""
    var password = ""
    
    var isSessionTimedOut: Bool {
        return Date().timeIntervalSince(sessionTime) > Double(sessionTimeOutInterval * 60)
    }
    
    private init(repository: SDKRepositoryProtocol = SDKRepository()) {
        self.sdkRepository = repository
    }
    
    public func initializeSdk(email: String?, password: String?, completion: @escaping (CognetSession?, SDKError?) -> Void) {
        if let _email = email, let _password = password {
            self.email = _email//"abc@a.com"
            self.password = _password//"asdwdwad"
        }
        
        Task {
            let initResult = await sdkRepository.initializeSDK(requstModel: .init(email: self.email, password: self.password))
            
            await MainActor.run {
                switch initResult {
                case .success(let response as SDKInitializeResponse):
                    APIHeader.shared.updateHeaders(initResponse: response)
                    
                    Task {
                        let configResult = await sdkRepository.getConfigurations()
                        
                        await MainActor.run {
                            switch configResult {
                            case .success(let configResponse):
                                // Do something with configResponse if needed
                                self.configurations = configResponse.configuration
                                self.sessionTime = Date()
                                self.sessionTimeOutInterval = configResponse.configuration.sSessionTimeout
                                let sdkResponse: CognetSession = .init(configuration: configResponse.configuration,
                                                                       token: response.token,
                                                                       sessionId: response.sessionId)
                                completion(sdkResponse, nil)
                                
                            case .failure(let error):
                                print("Configuration failed:", error.localizedDescription)
                                completion(nil, SDKError(message: error.localizedDescription))
                            }
                        }
                    }

                case .failure(let error):
                    completion(nil, SDKError(message: error.localizedDescription))
                    print("Initialization failed:", error.localizedDescription)
                }
            }
        }
    }
}
