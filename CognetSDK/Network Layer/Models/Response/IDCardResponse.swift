//
//  IDCardResponse.swift
//  CaptureFace
//
//  Created by Hadi Ali on 20/04/2025.
//

import Foundation

struct IDCardResponse: Codable {
    let result: IDCardResult

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            result = try container.decode(IDCardResult.self, forKey: .result)
        } catch {
            print("Failed to decode IDCardResponse: \(error)")
            throw error
        }
    }
}

public struct IDCardResult: Codable {
    public let dateOfBirth: String
    public let dateOfExpiry: String
    public let address: String?
    public let fullName: String?
    public let bookletNumber: String?
    public let dateOfIssue: String?
    public let documentName: String?
    public let issuingStateCode: String?
    public let issuingStateName: String?
    public let identityCardNumber: String
    public let mrz: IDCardMRZ?
    public let placeOfRegistration: String?
    public let placeofIssue: String?
    public let profession: String?
    public let sponsor: String?
    public let documentNumber: String?
    public let images: IDCardImages

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            dateOfBirth = try container.decode(String.self, forKey: .dateOfBirth)
            dateOfExpiry = try container.decode(String.self, forKey: .dateOfExpiry)
            address = try container.decodeIfPresent(String.self, forKey: .address)
            fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
            bookletNumber = try container.decodeIfPresent(String.self, forKey: .bookletNumber)
            dateOfIssue = try container.decodeIfPresent(String.self, forKey: .dateOfIssue)
            documentName = try container.decodeIfPresent(String.self, forKey: .documentName)
            issuingStateCode = try container.decodeIfPresent(String.self, forKey: .issuingStateCode)
            issuingStateName = try container.decodeIfPresent(String.self, forKey: .issuingStateName)
            identityCardNumber = try container.decode(String.self, forKey: .identityCardNumber)
            mrz = try container.decodeIfPresent(IDCardMRZ.self, forKey: .mrz)
            placeOfRegistration = try container.decodeIfPresent(String.self, forKey: .placeOfRegistration)
            placeofIssue = try container.decodeIfPresent(String.self, forKey: .placeofIssue)
            profession = try container.decodeIfPresent(String.self, forKey: .profession)
            sponsor = try container.decodeIfPresent(String.self, forKey: .sponsor)
            documentNumber = try container.decodeIfPresent(String.self, forKey: .documentNumber)
            images = try container.decode(IDCardImages.self, forKey: .images)
        } catch {
            print("Failed to decode IDCardResult: \(error)")
            throw error
        }
    }
    
    func isExpired() -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "UTC") // Optional: depends on use case
        
        guard let expiryDate = dateFormatter.date(from: dateOfExpiry) else {
            return true // Treat as expired if date format is invalid
        }
        
        return expiryDate.timeIntervalSince1970 < Date().timeIntervalSince1970
    }
}

public struct IDCardMRZ: Codable {
    public let dateOfBirth: String
    public let dateOfExpiry: String
    public let documentClassCode: String?
    public let documentNumber: String?
    public let fullName: String
    public let givenNames: String?
    public let identityCardNumber: String
    public let issuingStateCode: String
    public let issuingStateName: String?
    public let mrzCode: String
    public let mrzType: String?
    public let nationality: String?
    public let nationalityCode: String
    public let sex: String?
    public let surname: String?
    public let validation: Int?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            dateOfBirth = try container.decode(String.self, forKey: .dateOfBirth)
            dateOfExpiry = try container.decode(String.self, forKey: .dateOfExpiry)
            documentClassCode = try container.decodeIfPresent(String.self, forKey: .documentClassCode)
            documentNumber = try container.decodeIfPresent(String.self, forKey: .documentNumber)
            fullName = try container.decode(String.self, forKey: .fullName)
            givenNames = try container.decodeIfPresent(String.self, forKey: .givenNames)
            identityCardNumber = try container.decode(String.self, forKey: .identityCardNumber)
            issuingStateCode = try container.decode(String.self, forKey: .issuingStateCode)
            issuingStateName = try container.decodeIfPresent(String.self, forKey: .issuingStateName)
            mrzCode = try container.decode(String.self, forKey: .mrzCode)
            mrzType = try container.decodeIfPresent(String.self, forKey: .mrzType)
            nationality = try container.decodeIfPresent(String.self, forKey: .nationality)
            nationalityCode = try container.decode(String.self, forKey: .nationalityCode)
            sex = try container.decodeIfPresent(String.self, forKey: .sex)
            surname = try container.decodeIfPresent(String.self, forKey: .surname)
            validation = try container.decodeIfPresent(Int.self, forKey: .validation)
        } catch {
            print("Failed to decode IDCardMRZ: \(error)")
            throw error
        }
    }
}

public struct IDCardImages: Codable {
    public let documentFrontSide: String
    public let documentBackSide: String
    public let portrait: String
    
    enum CodingKeys: String, CodingKey {
        case documentFrontSide = "documentFrontSide"
        case documentBackSide = "documentBackSide"
        case portrait = "portrait"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            documentBackSide = try container.decode(String.self, forKey: .documentBackSide)
            documentFrontSide = try container.decode(String.self, forKey: .documentFrontSide)
            portrait = try container.decode(String.self, forKey: .portrait)
        } catch {
            print("Failed to decode IDCardImages: \(error)")
            throw error
        }
    }
}
