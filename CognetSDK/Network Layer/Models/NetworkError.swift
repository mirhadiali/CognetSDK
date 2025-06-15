//
//  NetworkError.swift
//  CaptureFace
//
//  Created by Hadi Ali on 18/04/2025.
//


enum NetworkError: Error {
    case invalidURL
    case decodingFailed
    case encodingFailed
    case invalidImageData
    case serverError(statusCode: Int)
    case badServerResponse  // ✅ Add this
    case unknown(Error)
    case apiError(message: String, details: String?)
}
