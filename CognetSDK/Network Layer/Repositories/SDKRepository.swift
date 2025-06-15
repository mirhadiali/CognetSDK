//
//  SDKRepository.swift
//  CaptureFace
//
//  Created by Hadi Ali on 12/05/2025.
//

import UIKit
import Foundation

protocol SDKRepositoryProtocol {
    var baseURL: String { get }
    func initializeSDK(requstModel: SDKInitializeRequest) async -> Result<SDKInitializeResponse, NetworkError>
    func getConfigurations() async -> Result<ConfigurationResponse, NetworkError>
}

final class SDKRepository: SDKRepositoryProtocol {
    private let networkService: NetworkServiceProtocol
    
    var baseURL: String {
        let urlString: String = AppEnvironment[.baseURL]
        return urlString
    }

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func initializeSDK(requstModel: SDKInitializeRequest) async -> Result<SDKInitializeResponse, NetworkError> {
        return await networkService.request(
            endpoint: "\(baseURL)/v1/sdk/Init",
            method: .POST,
            headers: APIHeader.shared.initializeSDKHeaders(),
            body: requstModel,
            queryParameters: nil,
            checkSessionTimeOut: false
        )
    }
    
    func getConfigurations() async -> Result<ConfigurationResponse, NetworkError> {
        return await networkService.request(
            endpoint: "\(baseURL)/v1/sdk/GetConfiguration",
            method: .GET,
            headers: APIHeader.shared.getHeader(),
            body: EmptyBody(),
            queryParameters: [:],
            checkSessionTimeOut: false
        )
    }
}
