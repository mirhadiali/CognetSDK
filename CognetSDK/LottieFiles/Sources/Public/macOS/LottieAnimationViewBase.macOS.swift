//
//  LottieAnimationViewBase.swift
//  lottie-swift-iOS
//
//  Created by Brandon Withrow on 2/6/19.
//

#if os(macOS)
import AppKit

enum LottieContentMode: Int {
  case scaleToFill
  case scaleAspectFit
  case scaleAspectFill
  case redraw
  case center
  case top
  case bottom
  case left
  case right
  case topLeft
  case topRight
  case bottomLeft
  case bottomRight
}

/// The base view for `LottieAnimationView` on macOs.
///
/// Enables the `LottieAnimationView` implementation to be shared across platforms.
class LottieAnimationViewBase: NSView {

  // MARK: Public

  override var wantsUpdateLayer: Bool {
    true
  }

  override var isFlipped: Bool {
    true
  }

  var contentMode = LottieContentMode.scaleAspectFit {
    didSet {
      setNeedsLayout()
    }
  }

  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    animationMovedToWindow()
  }

  override func layout() {
    super.layout()
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    layoutAnimation()
    CATransaction.commit()
  }

  // MARK: Internal

  var screenScale: CGFloat {
    NSApp.mainWindow?.backingScaleFactor ?? 1
  }

  var viewLayer: CALayer? {
    layer
  }

  func layoutAnimation() {
    // Implemented by subclasses.
  }

  func animationMovedToWindow() {
    // Implemented by subclasses.
  }

  func commonInit() {
    wantsLayer = true
  }

  func setNeedsLayout() {
    needsLayout = true
  }

  func layoutIfNeeded() {
    // Implemented by subclasses.
  }

  @objc
  func animationWillMoveToBackground() {
    // Implemented by subclasses.
  }

  @objc
  func animationWillEnterForeground() {
    // Implemented by subclasses.
  }

}
#endif
