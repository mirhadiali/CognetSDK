//
//  AnimationFontProvider.swift
//  Lottie
//
//  Created by Brandon Withrow on 8/5/20.
//  Copyright © 2020 YurtvilleProds. All rights reserved.
//

import CoreText

// MARK: - AnimationFontProvider

/// Font provider is a protocol that is used to supply fonts to `LottieAnimationView`.
///
protocol AnimationFontProvider {
  func fontFor(family: String, size: CGFloat) -> CTFont?
}

// MARK: - DefaultFontProvider

/// Default Font provider.
final class DefaultFontProvider: AnimationFontProvider {

  // MARK: Lifecycle

  init() { }

  // MARK: Public

  func fontFor(family: String, size: CGFloat) -> CTFont? {
    CTFontCreateWithName(family as CFString, size, nil)
  }
}

// MARK: Equatable

extension DefaultFontProvider: Equatable {
  static func ==(_: DefaultFontProvider, _: DefaultFontProvider) -> Bool {
    true
  }
}
