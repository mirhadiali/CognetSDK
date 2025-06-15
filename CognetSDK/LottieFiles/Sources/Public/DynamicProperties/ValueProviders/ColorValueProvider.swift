//
//  ColorValueProvider.swift
//  lottie-swift
//
//  Created by Brandon Withrow on 2/4/19.
//

import CoreGraphics
import Foundation

// MARK: - ColorValueProvider

/// A `ValueProvider` that returns a CGColor Value
final class ColorValueProvider: ValueProvider {

  // MARK: Lifecycle

  /// Initializes with a block provider
  init(block: @escaping ColorValueBlock) {
    self.block = block
    color = LottieColor(r: 0, g: 0, b: 0, a: 1)
    keyframes = nil
    identity = UUID()
  }

  /// Initializes with a single color.
  init(_ color: LottieColor) {
    self.color = color
    block = nil
    keyframes = nil
    hasUpdate = true
    identity = color
  }

  /// Initializes with multiple colors, with timing information
  init(_ keyframes: [Keyframe<LottieColor>]) {
    self.keyframes = keyframes
    color = LottieColor(r: 0, g: 0, b: 0, a: 1)
    block = nil
    hasUpdate = true
    identity = keyframes
  }

  // MARK: Public

  /// Returns a LottieColor for a CGColor(Frame Time)
  typealias ColorValueBlock = (CGFloat) -> LottieColor

  /// The color value of the provider.
  var color: LottieColor {
    didSet {
      hasUpdate = true
    }
  }

  // MARK: ValueProvider Protocol

  var valueType: Any.Type {
    LottieColor.self
  }

  var storage: ValueProviderStorage<LottieColor> {
    if let block {
      return .closure { frame in
        self.hasUpdate = false
        return block(frame)
      }
    } else if let keyframes {
      return .keyframes(keyframes)
    } else {
      hasUpdate = false
      return .singleValue(color)
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

  private var block: ColorValueBlock?
  private var keyframes: [Keyframe<LottieColor>]?
  private var identity: AnyHashable
}

// MARK: Equatable

extension ColorValueProvider: Equatable {
  static func ==(_ lhs: ColorValueProvider, _ rhs: ColorValueProvider) -> Bool {
    lhs.identity == rhs.identity
  }
}
