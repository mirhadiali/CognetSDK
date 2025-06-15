// Created by Cal Stephens on 7/14/23.
// Copyright © 2023 Airbnb Inc. All rights reserved.

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - ReducedMotionOption

/// Options for controlling animation behavior in response to user / system "reduced motion" configuration
enum ReducedMotionOption {
  /// Always use the specific given `ReducedMotionMode` value.
  case specific(ReducedMotionMode)

  /// Dynamically check the given `ReducedMotionOptionProvider` each time an animation begins.
  ///  - Includes a Hashable `dataID` to support `ReducedMotionOption`'s `Hashable` requirement,
  ///    which is required due to `LottieConfiguration`'s existing `Hashable` requirement.
  case dynamic(ReducedMotionOptionProvider, dataID: AnyHashable)
}

extension ReducedMotionOption {
  /// The standard behavior where Lottie animations play normally with no overrides.
  /// By default this mode is used when the system "reduced motion" option is disabled.
  static var standardMotion: ReducedMotionOption { .specific(.standardMotion) }

  /// Lottie animations with a "reduced motion" marker will play that marker instead of any other animations.
  /// By default this mode is used when the system "reduced motion" option is enabled.
  ///  - Valid marker names include "reduced motion", "reducedMotion", "reduced_motion" (case insensitive).
  static var reducedMotion: ReducedMotionOption { .specific(.reducedMotion) }

  /// A `ReducedMotionOptionProvider` that returns `.reducedMotion` when
  /// the system `UIAccessibility.isReduceMotionEnabled` option is `true`.
  /// This is the default option of `LottieConfiguration`.
  static var systemReducedMotionToggle: ReducedMotionOption {
    .dynamic(SystemReducedMotionOptionProvider(), dataID: ObjectIdentifier(SystemReducedMotionOptionProvider.self))
  }
}

extension ReducedMotionOption {
  /// The current `ReducedMotionMode` based on the currently selected option.
  var currentReducedMotionMode: ReducedMotionMode {
    switch self {
    case .specific(let specificMode):
      specificMode
    case .dynamic(let optionProvider, _):
      optionProvider.currentReducedMotionMode
    }
  }
}

// MARK: Hashable

extension ReducedMotionOption: Hashable {
  static func ==(_ lhs: ReducedMotionOption, _ rhs: ReducedMotionOption) -> Bool {
    switch (lhs, rhs) {
    case (.specific(let lhsMode), .specific(let rhsMode)):
      lhsMode == rhsMode
    case (.dynamic(_, let lhsDataID), .dynamic(_, dataID: let rhsDataID)):
      lhsDataID == rhsDataID
    case (.dynamic, .specific), (.specific, .dynamic):
      false
    }
  }

  func hash(into hasher: inout Hasher) {
    switch self {
    case .specific(let mode):
      hasher.combine(mode)
    case .dynamic(_, let dataID):
      hasher.combine(dataID)
    }
  }
}

// MARK: - ReducedMotionMode

enum ReducedMotionMode: Hashable {
  /// The default behavior where Lottie animations play normally with no overrides
  /// By default this mode is used when the system "reduced motion" option is disabled.
  case standardMotion

  /// Lottie animations with a "reduced motion" marker will play that marker instead of any other animations.
  /// By default this mode is used when the system "reduced motion" option is enabled.
  case reducedMotion
}

// MARK: - ReducedMotionOptionProvider

/// A type that returns a dynamic `ReducedMotionMode` which is checked when playing a Lottie animation.
protocol ReducedMotionOptionProvider {
  var currentReducedMotionMode: ReducedMotionMode { get }
}

// MARK: - SystemReducedMotionOptionProvider

/// A `ReducedMotionOptionProvider` that returns `.reducedMotion` when
/// the system `UIAccessibility.isReduceMotionEnabled` option is `true`.
struct SystemReducedMotionOptionProvider: ReducedMotionOptionProvider {
  init() { }

  var currentReducedMotionMode: ReducedMotionMode {
    #if canImport(UIKit)
    if UIAccessibility.isReduceMotionEnabled {
      return .reducedMotion
    } else {
      return .standardMotion
    }
    #else
    return .standardMotion
    #endif
  }
}
