//
//  UserRepository.swift
//  CaptureFace
//
//  Created by Hadi Ali on 18/04/2025.
//

import UIKit
import Foundation

protocol DocumentRepositoryProtocol {
    var baseURL: String { get }
    func verifyPassport(image: UIImage) async -> Result<PassportOCRResponse, NetworkError>
    func verifyIDCard(frontID: UIImage, backID: UIImage) async -> Result<IDCardResponse, NetworkError>
}

final class DocumentRepository: DocumentRepositoryProtocol {
    private let networkService: NetworkServiceProtocol
    var baseURL: String {
        let urlString: String = "https://kycdbd.cognetlabs.org"//AppEnvironment[.baseURL]
        return urlString
    }

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func verifyPassport(image: UIImage) async -> Result<PassportOCRResponse, NetworkError> {
        guard let base64Image = image.imageToBase64() else {
            let error = NSError(domain: "com.yourapp.passport", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to Base64"])
                return .failure(.unknown(error))
        }

        let requestBody = PassportOCRRequest(base64: base64Image)

        return await networkService.request(
//            endpoint: "http://94.136.189.101:8783/idcard_recognition_base64",
            endpoint: "\(baseURL)/v1/sdk/AnalyzePassport",
            method: .POST,
            headers: APIHeader.shared.getHeader(),
            body: requestBody,
            queryParameters: nil
        )
    }
    
    func verifyIDCard(frontID: UIImage, backID: UIImage) async -> Result<IDCardResponse, NetworkError> {
        guard let base64FrontImage = frontID.imageToBase64(), let base64BackImage = backID.imageToBase64()  else {
            let error = NSError(domain: "com.yourapp.passport", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to Base64"])
                return .failure(.unknown(error))
        }

        let requestBody = IDCardRequest(base64_1: base64FrontImage, base64_2: base64BackImage)

        return await networkService.request(
//            endpoint: "http://94.136.189.101:8783/idcard_recognition_base64_multi_page",
            endpoint: "\(baseURL)/v1/sdk/AnalyzeIDCard",
            method: .POST,
            headers: APIHeader.shared.getHeader(),
            body: requestBody,
            queryParameters: nil
        )
    }
}

extension UIImage {
    func imageToBase64() -> String? {
        guard let imageData = self.jpegData(compressionQuality: 0.99) else {
            return nil
        }
        return imageData.base64EncodedString()
    }
}
