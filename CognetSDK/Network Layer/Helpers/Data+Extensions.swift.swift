//
//  Data+Extensions.swift.swift
//  CaptureFace
//
//  Created by Hadi Ali on 18/04/2025.
//
import Foundation

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
