//
//  ConfigurationResponse.swift
//  CaptureFace
//
//  Created by Hadi Ali on 12/05/2025.
//


import Foundation

struct ConfigurationResponse: Codable {
    let isSuccess: Bool
    let message: String
    let configuration: Configurations
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isSuccess = try container.decodeIfPresent(Bool.self, forKey: .isSuccess) ?? false
        self.message = try container.decode(String.self, forKey: .message)
        self.configuration = try container.decode(Configurations.self, forKey: .configuration)
    }
}

public struct Configurations: Codable, Identifiable {
    public var id = UUID()
    public let sSessionTimeout: Int
    public let onboardingFlow: OnboardingFlow
    public let verificationFlow: VerificationFlow
    public let clientPrivCov: String?
    public let backendPubCov: String?

    enum CodingKeys: String, CodingKey {
        case sSessionTimeout = "s_SessionTimeout"
        case onboardingFlow
        case verificationFlow
        case clientPrivCov = "client_priv_cov"
        case backendPubCov = "backend_pub_cov"
    }
    
    public func getOnboardingSteps() -> [Steps] {
        var steps: [Steps] = [.info]
        
        if onboardingFlow.documentEngine.idCard {
            steps.append(.idcard)
        } else if  onboardingFlow.documentEngine.passport {
            steps.append(.passport)
        }
        if onboardingFlow.faceEngine {
            steps.append(.face)
        }
        
        if onboardingFlow.palmEngine {
            steps.append(.faceHand)
            steps.append(.hand)
        }
        steps.append(.complete)
        return steps
    }
    
    public func getVerificationSteps() -> [Steps] {
        var steps: [Steps] = []
        if verificationFlow.faceEngine {
            steps.append(.face)
        } else if verificationFlow.palmEngine {
            steps.append(.hand)
        }
        return steps
    }
}
extension Configurations {
    static func mock() -> Configurations {
        return .init(sSessionTimeout: 60, onboardingFlow: .init(documentEngine: .init(passport: true, idCard: false),
                                                                faceEngine: true, palmEngine: false),
                     verificationFlow: .init(faceEngine: true, palmEngine: false),
                     clientPrivCov: "", backendPubCov: "")
    }
}

public struct OnboardingFlow: Codable {
    public let documentEngine: DocumentEngine
    public let faceEngine: Bool
    public let palmEngine: Bool
}

public struct DocumentEngine: Codable {
    public  let passport: Bool
    public  let idCard: Bool
}

public struct VerificationFlow: Codable {
    public let faceEngine: Bool
    public let palmEngine: Bool
}
