//
//  Bundle+Extension.swift
//  CognetSDK
//
//  Created by Hadi Ali on 16/06/2025.
//
import Foundation

extension Bundle {
    static var cognetSDKBundle: Bundle {
        return Bundle(for: CognetSDKBundleReference.self)
    }
}
public class CognetSDKBundleReference: NSObject {}
