//
//  HTTPMethod.swift
//  CaptureFace
//
//  Created by Hadi Ali on 18/04/2025.
//


import Foundation

protocol NetworkServiceProtocol {
    func request<T: Decodable, B: Encodable>(
        endpoint: String,
        method: HTTPMethod,
        headers: [String: String]?,
        body: B?,
        queryParameters: [String: String]?,
        checkSessionTimeOut: Bool
        
    ) async -> Result<T, NetworkError>
}

extension NetworkServiceProtocol {
    func request<T: Decodable, B: Encodable>(
        endpoint: String,
        method: HTTPMethod,
        headers: [String: String]? = nil,
        body: B? = nil,
        queryParameters: [String: String]? = nil,
        checkSessionTimeOut: Bool = true
    ) async -> Result<T, NetworkError> {
        await request(
            endpoint: endpoint,
            method: method,
            headers: headers,
            body: body,
            queryParameters: queryParameters,
            checkSessionTimeOut: checkSessionTimeOut
        )
    }
}
extension CognetSDKManager {
    func initializeSdkAsync() async {
        await withCheckedContinuation { continuation in
            self.initializeSdk(email: nil, password: nil) { configurations, errorMessage in
                print("sdk initialized")
                continuation.resume()
            }
        }
    }
}

final class NetworkService: NetworkServiceProtocol {
    
    private let session: URLSession
    private let logger: NetworkLoggerProtocol
    
    init(session: URLSession = URLSession.shared, logger: NetworkLoggerProtocol = ConsoleLogger()) {
        self.session = session
        self.logger = logger
    }

    func request<T: Decodable, B: Encodable>(
        endpoint: String,
        method: HTTPMethod,
        headers: [String: String]? = nil,
        body: B? = nil,
        queryParameters: [String: String]? = nil,
        checkSessionTimeOut: Bool = true
    ) async -> Result<T, NetworkError> {

        if CognetSDKManager.shared.isSessionTimedOut, checkSessionTimeOut {
            await CognetSDKManager.shared.initializeSdkAsync()
        }
        
        var urlComponents = URLComponents(string: endpoint)
        if method == .GET, let queryParameters = queryParameters {
            urlComponents?.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = urlComponents?.url else {
            return .failure(.invalidURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        if let body = body, method != .GET {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                return .failure(.encodingFailed)
            }
        }

        logger.logRequest(request)

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.badServerResponse)
            }

            logger.logResponse(data: data, response: httpResponse)

            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to decode error response
                if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                    return .failure(.apiError(message: apiError.message ?? "Unknown error", details: apiError.details))
                } else {
                    return .failure(.serverError(statusCode: httpResponse.statusCode))
                }
            }

            let decoded = try JSONDecoder().decode(T.self, from: data)
            return .success(decoded)

        } catch {
            return .failure(.unknown(error))
        }
    }
}
struct APIErrorResponse: Decodable {
    let details: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case details = "Details"
        case message = "Message"
    }
}
