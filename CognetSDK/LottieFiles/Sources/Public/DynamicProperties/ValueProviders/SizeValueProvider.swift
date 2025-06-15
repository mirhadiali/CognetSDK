//
//  SizeValueProvider.swift
//  lottie-swift
//
//  Created by Brandon Withrow on 2/4/19.
//

import CoreGraphics
import Foundation

// MARK: - SizeValueProvider

/// A `ValueProvider` that returns a CGSize Value
final class SizeValueProvider: ValueProvider {

  // MARK: Lifecycle

  /// Initializes with a block provider
  init(block: @escaping SizeValueBlock) {
    self.block = block
    size = .zero
    identity = UUID()
  }

  /// Initializes with a single size.
  init(_ size: CGSize) {
    self.size = size
    block = nil
    hasUpdate = true
    identity = [size.width, size.height]
  }

  // MARK: Public

  /// Returns a CGSize for a CGFloat(Frame Time)
  typealias SizeValueBlock = (CGFloat) -> CGSize

  var size: CGSize {
    didSet {
      hasUpdate = true
    }
  }

  // MARK: ValueProvider Protocol

  var valueType: Any.Type {
    LottieVector3D.self
  }

  var storage: ValueProviderStorage<LottieVector3D> {
    if let block {
      return .closure { frame in
        self.hasUpdate = false
        return block(frame).vector3dValue
      }
    } else {
      hasUpdate = false
      return .singleValue(size.vector3dValue)
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

  private var block: SizeValueBlock?
  private let identity: AnyHashable
}

// MARK: Equatable

extension SizeValueProvider: Equatable {
  static func ==(_ lhs: SizeValueProvider, _ rhs: SizeValueProvider) -> Bool {
    lhs.identity == rhs.identity
  }
}
