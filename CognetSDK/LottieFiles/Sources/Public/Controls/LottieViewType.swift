// Created by Cal Stephens on 8/11/23.
// Copyright © 2023 Airbnb Inc. All rights reserved.

#if canImport(UIKit)
import UIKit

/// The control base type for this platform.
///  - `UIControl` on iOS / tvOS and `NSControl` on macOS.
typealias LottieControlType = UIControl

/// The `State` type of `LottieControlType`
///  - `UIControl.State` on iOS / tvOS and `NSControl.StateValue` on macOS.
typealias LottieControlState = UIControl.State

/// The event type handled by the `LottieControlType` component for this platform.
///  - `UIControl.Event` on iOS / tvOS and `LottieNSControlEvent` on macOS.
typealias LottieControlEvent = UIControl.Event

extension LottieControlEvent {
  var id: AnyHashable {
    rawValue
  }
}
#else
import AppKit

/// The control base type for this platform.
///  - `UIControl` on iOS / tvOS and `NSControl` on macOS.
typealias LottieControlType = NSControl

/// The `State` type of `LottieControlType`
///  - `UIControl.State` on iOS / tvOS and `NSControl.StateValue` on macOS.
typealias LottieControlState = LottieNSControlState

/// AppKit equivalent of `UIControl.State` for `AnimatedControl`
enum LottieNSControlState: UInt, RawRepresentable {
  /// The normal, or default, state of a control where the control is enabled but neither selected nor highlighted.
  case normal
  /// The highlighted state of a control.
  case highlighted
}

/// The event type handled by the `LottieControlType` component for this platform.
///  - `UIControl.Event` on iOS / tvOS and `LottieNSControlEvent` on macOS.
typealias LottieControlEvent = LottieNSControlEvent

struct LottieNSControlEvent: Equatable, Sendable {

  // MARK: Lifecycle

  init(_ event: NSEvent.EventType, inside: Bool) {
    self.event = event
    self.inside = inside
  }

  // MARK: Public

  /// macOS equivalent to `UIControl.Event.touchDown`
  static let touchDown = LottieNSControlEvent(.leftMouseDown, inside: true)

  /// macOS equivalent to `UIControl.Event.touchUpInside`
  static let touchUpInside = LottieNSControlEvent(.leftMouseUp, inside: true)

  /// macOS equivalent to `UIControl.Event.touchUpInside`
  static let touchUpOutside = LottieNSControlEvent(.leftMouseUp, inside: false)

  /// The underlying `NSEvent.EventType` of this event, which is roughly equivalent to `UIControl.Event`
  var event: NSEvent.EventType

  /// Whether or not the mouse must be inside the control.
  var inside: Bool

  // MARK: Internal

  var id: AnyHashable {
    [AnyHashable(event.rawValue), AnyHashable(inside)]
  }
}
#endif
