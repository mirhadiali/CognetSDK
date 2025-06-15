//
//  NetworkLoggerProtocol.swift
//  CaptureFace
//
//  Created by Hadi Ali on 18/04/2025.
//

import Foundation

protocol NetworkLoggerProtocol {
    func logRequest(_ request: URLRequest)
    func logResponse(data: Data, response: HTTPURLResponse)
}

final class ConsoleLogger: NetworkLoggerProtocol {
    func logRequest(_ request: URLRequest) {
        print("➡️ Request: \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")")
        if let headers = request.allHTTPHeaderFields {
            print("Headers: \(headers)")
        }
        if let body = request.httpBody,
           let json = try? JSONSerialization.jsonObject(with: body, options: []) {
            print("Body: \(json)")
        }
    }

    func logResponse(data: Data, response: HTTPURLResponse) {
        print("⬅️ Response: \(response.statusCode) ✅")
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            print("Response JSON: \(json)")
        }
    }
}
