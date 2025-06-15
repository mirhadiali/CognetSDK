//
//  FaceHandRepository.swift
//  CaptureFace
//
//  Created by Hadi Ali on 13/05/2025.
//

import UIKit
import Foundation

protocol FaceHandRepositoryProtocol {
    var baseURL: String { get }
    func checkLiveness(faceImage: UIImage) async -> Result<LivenessResponse, NetworkError>
    func faceVerifyAndSearch(documentImage: String, faceImage: UIImage) async -> Result<VerifyAndSearchResponse, NetworkError>
    func faceVerify(face1: String, face2: String) async -> Result<VerifyFaceResponse, NetworkError>
    func handVerifyAndSearch(hand1: UIImage, hand2: UIImage) async -> Result<VerifyAndSearchResponse, NetworkError>
    func biometricLogin(request: BiometricLoginRequestModel) async -> Result<BiometricLoginResponse, NetworkError>
    func biometricVerify(request: BiometricVerifyRequestModel) async -> Result<VerificationResponse, NetworkError>
}


final class FaceHandRepository: FaceHandRepositoryProtocol {
    private let networkService: NetworkServiceProtocol
    var baseURL: String {
        let urlString: String = AppEnvironment[.baseURL]
        return urlString
    }
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func checkLiveness(faceImage: UIImage) async -> Result<LivenessResponse, NetworkError> {
        guard let base64Image = faceImage.imageToBase64() else {
            let error = NSError(domain: "com.yourapp.face", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to Base64"])
            return .failure(.unknown(error))
        }
        
        let requestBody = FaceLivenessRequest(base64_image: base64Image)
        
        return await networkService.request(
            endpoint: "\(baseURL)/v1/sdk/CheckFaceLiveness",
            method: .POST,
            headers: APIHeader.shared.getHeader(),
            body: requestBody,
            queryParameters: nil
        )
    }
    
    func faceVerifyAndSearch(documentImage: String, faceImage: UIImage) async -> Result<VerifyAndSearchResponse, NetworkError> {
        guard let base64Image = faceImage.imageToBase64() else {
            let error = NSError(domain: "com.yourapp.face", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to Base64"])
            return .failure(.unknown(error))
        }
        
        let requestBody = VerifyAndSearchRequest(biometricType: .face, image_1: documentImage, image_2: base64Image, isPortrait: true)
        
        return await networkService.request(
            endpoint: "\(baseURL)/v1/sdk/VerifyAndSearch",
            method: .POST,
            headers: APIHeader.shared.getHeader(),
            body: requestBody,
            queryParameters: nil
        )
    }
    
    func faceVerify(face1: String, face2: String) async -> Result<VerifyFaceResponse, NetworkError> {
//        guard let base64Image1 = face1.imageToBase64(),
//              let base64Image2 = face2.imageToBase64() else {
//            let error = NSError(domain: "com.yourapp.face", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to Base64"])
//            return .failure(.unknown(error))
//        }
        
        let requestBody = VerifyAndSearchRequest(biometricType: .face, image_1: face1, image_2: face2, isPortrait: false)
        
        return await networkService.request(
            endpoint: "\(baseURL)/v1/sdk/Verify",
            method: .POST,
            headers: APIHeader.shared.getHeader(),
            body: requestBody,
            queryParameters: nil
        )
    }
    
    func handVerifyAndSearch(hand1: UIImage, hand2: UIImage) async -> Result<VerifyAndSearchResponse, NetworkError> {
        guard  let base64Image1 = hand1.imageToBase64(),
               let base64Image2 = hand2.imageToBase64() else {
            let error = NSError(domain: "com.yourapp.face", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to Base64"])
            return .failure(.unknown(error))
        }
        
        let requestBody = VerifyAndSearchRequest(biometricType: .palm, image_1: base64Image1, image_2: base64Image2, isPortrait: true)
        
        return await networkService.request(
            endpoint: "\(baseURL)/v1/sdk/VerifyAndSearch",
            method: .POST,
            headers: APIHeader.shared.getHeader(),
            body: requestBody,
            queryParameters: nil
        )
    }
    
    func biometricLogin(request: BiometricLoginRequestModel) async -> Result<BiometricLoginResponse, NetworkError> {
        return await networkService.request(
            endpoint: "\(baseURL)/v1/customer/BiometricLogin",
            method: .POST,
            headers: APIHeader.shared.getHeader(),
            body: request,
            queryParameters: nil
        )
    }
    
    func biometricVerify(request: BiometricVerifyRequestModel) async -> Result<VerificationResponse, NetworkError> {
        return await networkService.request(
            endpoint: "\(baseURL)/v1/customer/BiometricVerify",
            method: .POST,
            headers: APIHeader.shared.getHeader(),
            body: request,
            queryParameters: nil
        )
    }
}
