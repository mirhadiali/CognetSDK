//
//  PassportOCRResponse.swift
//  CaptureFace
//
//  Created by Hadi Ali on 20/04/2025.
//


import Foundation

struct PassportOCRResponse: Codable {
    let result: PassportResult
    
    enum CodingKeys: String, CodingKey {
        case result = "result"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            result = try container.decode(PassportResult.self, forKey: .result)
        } catch {
            print("📛 Decoding PassportOCRResponse failed: \(error)")
            throw error
        }
    }
}

public struct PassportResult: Codable {
    public let authority: String?
    public let dateOfBirth: String?
    public let dateOfExpiry: String?
    public let dateOfIssue: String?
    public let documentClassCode: String?
    public let documentName: String?
    public let documentNumber: String?
    public let documentStatus: String?
    public let fullName: String?
    public let images: PassportImages
    public let issuingStateCode: String?
    public let issuingStateName: String?
    public let mrz: PassportMRZ
    public let personalNumber: String?
    public let nationality: String?
    public let placeOfBirth: String?
    public let sex: String?
    public let status: String?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            authority = try container.decodeIfPresent(String.self, forKey: .authority)
            dateOfBirth = try container.decodeIfPresent(String.self, forKey: .dateOfBirth)
            dateOfExpiry = try container.decodeIfPresent(String.self, forKey: .dateOfExpiry)
            dateOfIssue = try container.decodeIfPresent(String.self, forKey: .dateOfIssue)
            documentClassCode = try container.decodeIfPresent(String.self, forKey: .documentClassCode)
            documentName = try container.decodeIfPresent(String.self, forKey: .documentName)
            documentNumber = try container.decodeIfPresent(String.self, forKey: .documentNumber)
            documentStatus = try? container.decodeIfPresent(String.self, forKey: .documentStatus)
            fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
            images = try container.decode(PassportImages.self, forKey: .images)
            issuingStateCode = try container.decodeIfPresent(String.self, forKey: .issuingStateCode)
            issuingStateName = try container.decodeIfPresent(String.self, forKey: .issuingStateName)
            mrz = try container.decode(PassportMRZ.self, forKey: .mrz)
            personalNumber = try container.decodeIfPresent(String.self, forKey: .personalNumber)
            nationality = try container.decodeIfPresent(String.self, forKey: .nationality)
            placeOfBirth = try container.decodeIfPresent(String.self, forKey: .placeOfBirth)
            sex = try container.decodeIfPresent(String.self, forKey: .sex)
            status = try container.decodeIfPresent(String.self, forKey: .status)
        } catch {
            print("📛 Decoding PassportResult failed: \(error)")
            throw error
        }
    }
}

public struct PassportImages: Codable {
    public let documentFrontSide: String
    public let portrait: String
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            documentFrontSide = try container.decode(String.self, forKey: .documentFrontSide)
            portrait = try container.decode(String.self, forKey: .portrait)
        } catch {
            print("📛 Decoding PassportImages failed: \(error)")
            throw error
        }
    }
}

public struct PassportMRZ: Codable {
    public let dateOfBirth: String
    public let dateOfExpiry: String
    public let documentClassCode: String?
    public let documentNumber: String
    public let personalNumber: String?
    public let fullName: String
    public let givenNames: String?
    public let issuingStateCode: String
    public let issuingStateName: String?
    public let mrzCode: String
    public let mrzType: String?
    public let nationalityCode: String
    public let sex: String?
    public let surname: String?
    public let validation: Int?
    
    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            dateOfBirth = try container.decode(String.self, forKey: .dateOfBirth)
            dateOfExpiry = try container.decode(String.self, forKey: .dateOfExpiry)
            documentClassCode = try container.decodeIfPresent(String.self, forKey: .documentClassCode)
            documentNumber = try container.decode(String.self, forKey: .documentNumber)
            personalNumber = try container.decodeIfPresent(String.self, forKey: .personalNumber)
            fullName = try container.decode(String.self, forKey: .fullName)
            givenNames = try container.decodeIfPresent(String.self, forKey: .givenNames)
            issuingStateCode = try container.decode(String.self, forKey: .issuingStateCode)
            issuingStateName = try container.decodeIfPresent(String.self, forKey: .issuingStateName)
            mrzCode = try container.decode(String.self, forKey: .mrzCode)
            mrzType = try container.decodeIfPresent(String.self, forKey: .mrzType)
            nationalityCode = try container.decode(String.self, forKey: .nationalityCode)
            sex = try container.decodeIfPresent(String.self, forKey: .sex)
            surname = try container.decodeIfPresent(String.self, forKey: .surname)
            validation = try container.decodeIfPresent(Int.self, forKey: .validation)
        } catch {
            print("📛 Decoding PassportMRZ failed: \(error)")
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

extension PassportMRZ {
    
    // Assumes format is "yyyy-MM-dd"
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let date = formatter.date(from: dateString) else { return "" }
        
        let output = DateFormatter()
        output.dateFormat = "yyMMdd"
        return output.string(from: date)
    }
    
    func generateMRZKey() -> String {
        let docNumber = documentNumber.padding(toLength: 9, withPad: "<", startingAt: 0)
        let dob = formatDate(dateOfBirth)
        let expiry = formatDate(dateOfExpiry)
        
        
        let passportUtility = PassportUtils()
        return passportUtility.getMRZKey(passportNumber: docNumber, dateOfBirth: dob, dateOfExpiry: expiry)
    }
}
