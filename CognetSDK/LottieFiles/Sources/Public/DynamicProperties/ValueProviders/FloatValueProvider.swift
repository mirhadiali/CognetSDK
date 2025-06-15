//
//  DoubleValueProvider.swift
//  lottie-swift
//
//  Created by Brandon Withrow on 2/4/19.
//

import CoreGraphics
import Foundation

// MARK: - FloatValueProvider

/// A `ValueProvider` that returns a CGFloat Value
final class FloatValueProvider: ValueProvider {

  // MARK: Lifecycle

  /// Initializes with a block provider
  init(block: @escaping CGFloatValueBlock) {
    self.block = block
    float = 0
    identity = UUID()
  }

  /// Initializes with a single float.
  init(_ float: CGFloat) {
    self.float = float
    block = nil
    hasUpdate = true
    identity = float
  }

  // MARK: Public

  /// Returns a CGFloat for a CGFloat(Frame Time)
  typealias CGFloatValueBlock = (CGFloat) -> CGFloat

  var float: CGFloat {
    didSet {
      hasUpdate = true
    }
  }

  // MARK: ValueProvider Protocol

  var valueType: Any.Type {
    LottieVector1D.self
  }

  var storage: ValueProviderStorage<LottieVector1D> {
    if let block {
      return .closure { frame in
        self.hasUpdate = false
        return LottieVector1D(Double(block(frame)))
      }
    } else {
      hasUpdate = false
      return .singleValue(LottieVector1D(Double(float)))
    }
  }

  func hasUpdate(frame _: CGFloat) -> Bool {
    if block != nil {
      return true
    }
    return hasUpdate
  }

  // MARK: Private

  private var hasUpdate = true

  private var block: CGFloatValueBlock?
  private var identity: AnyHashable
}

// MARK: Equatable

extension FloatValueProvider: Equatable {
  static func ==(_ lhs: FloatValueProvider, _ rhs: FloatValueProvider) -> Bool {
    lhs.identity == rhs.identity
  }
}
