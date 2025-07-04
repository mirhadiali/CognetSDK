//
//  TextLayer.swift
//  Pods
//
//  Created by Brandon Withrow on 8/3/20.
//

import CoreGraphics
import CoreText
import Foundation
import QuartzCore
/// Needed for NSMutableParagraphStyle...
#if os(OSX)
import AppKit
#else
import UIKit
#endif

// MARK: - CoreTextRenderLayer

/// A CALayer subclass that renders text content using CoreText
final class CoreTextRenderLayer: CALayer {

  // MARK: Public

  var text: String? {
    didSet {
      needsContentUpdate = true
      setNeedsLayout()
      setNeedsDisplay()
    }
  }

  var font: CTFont? {
    didSet {
      needsContentUpdate = true
      setNeedsLayout()
      setNeedsDisplay()
    }
  }

  var alignment = NSTextAlignment.left {
    didSet {
      needsContentUpdate = true
      setNeedsLayout()
      setNeedsDisplay()
    }
  }

  var lineHeight: CGFloat = 0 {
    didSet {
      needsContentUpdate = true
      setNeedsLayout()
      setNeedsDisplay()
    }
  }

  var tracking: CGFloat = 0 {
    didSet {
      needsContentUpdate = true
      setNeedsLayout()
      setNeedsDisplay()
    }
  }

  var fillColor: CGColor? {
    didSet {
      needsContentUpdate = true
      setNeedsLayout()
      setNeedsDisplay()
    }
  }

  var strokeColor: CGColor? {
    didSet {
      needsContentUpdate = true
      setNeedsLayout()
      setNeedsDisplay()
    }
  }

  var strokeWidth: CGFloat = 0 {
    didSet {
      needsContentUpdate = true
      setNeedsLayout()
      setNeedsDisplay()
    }
  }

  var strokeOnTop = false {
    didSet {
      setNeedsLayout()
      setNeedsDisplay()
    }
  }

  var preferredSize: CGSize? {
    didSet {
      needsContentUpdate = true
      setNeedsLayout()
      setNeedsDisplay()
    }
  }

  var start: Int? {
    didSet {
      needsContentUpdate = true
      setNeedsLayout()
      setNeedsDisplay()
    }
  }

  var end: Int? {
    didSet {
      needsContentUpdate = true
      setNeedsLayout()
      setNeedsDisplay()
    }
  }

  /// The type of unit to use when computing the `start` / `end` range within the text string
  var textRangeUnit: TextRangeUnit? {
    didSet {
      needsContentUpdate = true
      setNeedsLayout()
      setNeedsDisplay()
    }
  }

  /// The opacity to apply to the range between `start` and `end`
  var selectedRangeOpacity: CGFloat? {
    didSet {
      needsContentUpdate = true
      setNeedsLayout()
      setNeedsDisplay()
    }
  }

  func sizeToFit() {
    updateTextContent()
    bounds = drawingRect
    anchorPoint = drawingAnchor
    setNeedsLayout()
    setNeedsDisplay()
  }

  // MARK: Internal

  override func action(forKey _: String) -> CAAction? {
    nil
  }

  override func draw(in ctx: CGContext) {
    guard let attributedString else { return }
    updateTextContent()
    guard fillFrameSetter != nil || strokeFrameSetter != nil else { return }

    ctx.textMatrix = .identity
    ctx.setAllowsAntialiasing(true)
    ctx.setAllowsFontSubpixelPositioning(true)
    ctx.setAllowsFontSubpixelQuantization(true)

    ctx.setShouldAntialias(true)
    ctx.setShouldSubpixelPositionFonts(true)
    ctx.setShouldSubpixelQuantizeFonts(true)

    if contentsAreFlipped() {
      ctx.translateBy(x: 0, y: drawingRect.height)
      ctx.scaleBy(x: 1.0, y: -1.0)
    }

    let drawingPath = CGPath(rect: drawingRect, transform: nil)

    let fillFrame: CTFrame? =
      if let setter = fillFrameSetter {
        CTFramesetterCreateFrame(setter, CFRangeMake(0, attributedString.length), drawingPath, nil)
      } else {
        nil
      }

    let strokeFrame: CTFrame? =
      if let setter = strokeFrameSetter {
        CTFramesetterCreateFrame(setter, CFRangeMake(0, attributedString.length), drawingPath, nil)
      } else {
        nil
      }

    // This fixes a vertical padding issue that arises when drawing some fonts.
    // For some reason some fonts, such as Helvetica draw with and ascender that is greater than the one reported by CTFontGetAscender.
    // I suspect this is actually an issue with the Attributed string, but cannot reproduce.

    if let fillFrame {
      ctx.adjustWithLineOrigins(in: fillFrame, with: font)
    } else if let strokeFrame {
      ctx.adjustWithLineOrigins(in: strokeFrame, with: font)
    }

    if !strokeOnTop, let strokeFrame {
      CTFrameDraw(strokeFrame, ctx)
    }

    if let fillFrame {
      CTFrameDraw(fillFrame, ctx)
    }

    if strokeOnTop, let strokeFrame {
      CTFrameDraw(strokeFrame, ctx)
    }
  }

  // MARK: Private

  private var drawingRect = CGRect.zero
  private var drawingAnchor = CGPoint.zero
  private var fillFrameSetter: CTFramesetter?
  private var attributedString: NSAttributedString?
  private var strokeFrameSetter: CTFramesetter?
  private var needsContentUpdate = false

  private func updateTextContent() {
    guard needsContentUpdate else { return }
    needsContentUpdate = false
    guard let font, let text, text.count > 0, fillColor != nil || strokeColor != nil else {
      drawingRect = .zero
      drawingAnchor = .zero
      attributedString = nil
      fillFrameSetter = nil
      strokeFrameSetter = nil
      return
    }

    // Get Font properties
    let ascent = CTFontGetAscent(font)
    let descent = CTFontGetDescent(font)
    let capHeight = CTFontGetCapHeight(font)
    let leading = CTFontGetLeading(font)
    let minLineHeight = -(ascent + descent + leading)

    // Calculate line spacing
    let lineSpacing = max(CGFloat(minLineHeight) + lineHeight, CGFloat(minLineHeight))
    // Build Attributes
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = lineSpacing
    paragraphStyle.lineHeightMultiple = 1
    paragraphStyle.maximumLineHeight = ascent + descent + leading
    paragraphStyle.alignment = alignment
    paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
    var attributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.ligature: 0,
      NSAttributedString.Key.font: font,
      NSAttributedString.Key.kern: tracking,
      NSAttributedString.Key.paragraphStyle: paragraphStyle,
    ]

    if let fillColor {
      attributes[NSAttributedString.Key.foregroundColor] = fillColor
    }

    let attrString = NSMutableAttributedString(string: text, attributes: attributes)

    // Apply the text animator within between the `start` and `end` indices
    if let selectedRangeOpacity {
      // The start and end of a text animator refer to the portions of the text
      // where that animator is applies. In the schema these can be represented
      // in absolute index value, or as percentages relative to the dynamic string length.
      var startIndex: Int
      var endIndex: Int

      switch textRangeUnit ?? .percentage {
      case .index:
        startIndex = start ?? 0
        endIndex = end ?? text.count

      case .percentage:
        let startPercentage = Double(start ?? 0) / 100
        let endPercentage = Double(end ?? 100) / 100

        startIndex = Int(round(Double(attrString.length) * startPercentage))
        endIndex = Int(round(Double(attrString.length) * endPercentage))
      }

      // Carefully cap the indices, since passing invalid indices
      // to `NSAttributedString` will crash the app.
      startIndex = startIndex.clamp(0, attrString.length)
      endIndex = endIndex.clamp(0, attrString.length)

      // Make sure the end index actually comes after the start index
      if endIndex < startIndex {
        swap(&startIndex, &endIndex)
      }

      // Apply the `selectedRangeOpacity` to the current `fillColor` if provided
      let textRangeColor: CGColor
      if let fillColor {
        if let (r, g, b) = fillColor.rgb {
          textRangeColor = .rgba(r, g, b, selectedRangeOpacity)
        } else {
          LottieLogger.shared.warn("Could not convert color \(fillColor) to RGB values.")
          textRangeColor = .rgba(0, 0, 0, selectedRangeOpacity)
        }
      } else {
        textRangeColor = .rgba(0, 0, 0, selectedRangeOpacity)
      }

      attrString.addAttribute(
        NSAttributedString.Key.foregroundColor,
        value: textRangeColor,
        range: NSRange(location: startIndex, length: endIndex - startIndex))
    }

    attributedString = attrString

    if fillColor != nil {
      let setter = CTFramesetterCreateWithAttributedString(attrString as CFAttributedString)
      fillFrameSetter = setter
    } else {
      fillFrameSetter = nil
    }

    if let strokeColor {
      attributes[NSAttributedString.Key.foregroundColor] = nil
      attributes[NSAttributedString.Key.strokeWidth] = strokeWidth
      attributes[NSAttributedString.Key.strokeColor] = strokeColor
      let strokeAttributedString = NSAttributedString(string: text, attributes: attributes)
      strokeFrameSetter = CTFramesetterCreateWithAttributedString(strokeAttributedString as CFAttributedString)
    } else {
      strokeFrameSetter = nil
      strokeWidth = 0
    }

    guard let setter = fillFrameSetter ?? strokeFrameSetter else {
      return
    }

    // Calculate drawing size and anchor offset
    let textAnchor: CGPoint
    if let preferredSize {
      drawingRect = CGRect(origin: .zero, size: preferredSize)
      drawingRect.size.height += (ascent - capHeight)
      drawingRect.size.height += descent
      textAnchor = CGPoint(x: 0, y: ascent - capHeight)
    } else {
      let size = CTFramesetterSuggestFrameSizeWithConstraints(
        setter,
        CFRange(location: 0, length: attrString.length),
        nil,
        CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
        nil)
      switch alignment {
      case .left:
        textAnchor = CGPoint(x: 0, y: ascent)
      case .right:
        textAnchor = CGPoint(x: size.width, y: ascent)
      case .center:
        textAnchor = CGPoint(x: size.width * 0.5, y: ascent)
      default:
        textAnchor = .zero
      }
      drawingRect = CGRect(
        x: 0,
        y: 0,
        width: ceil(size.width),
        height: ceil(size.height))
    }

    // Now Calculate Anchor
    drawingAnchor = CGPoint(
      x: textAnchor.x.remap(fromLow: 0, fromHigh: drawingRect.size.width, toLow: 0, toHigh: 1),
      y: textAnchor.y.remap(fromLow: 0, fromHigh: drawingRect.size.height, toLow: 0, toHigh: 1))

    if fillFrameSetter != nil, strokeFrameSetter != nil {
      drawingRect.size.width += strokeWidth
      drawingRect.size.height += strokeWidth
    }
  }

}

extension CGContext {

  fileprivate func adjustWithLineOrigins(in frame: CTFrame, with font: CTFont?) {
    guard let font else { return }

    let count = CFArrayGetCount(CTFrameGetLines(frame))

    guard count > 0 else { return }

    var o = [CGPoint](repeating: .zero, count: 1)
    CTFrameGetLineOrigins(frame, CFRange(location: count - 1, length: 1), &o)

    let diff = CTFontGetDescent(font) - o[0].y
    if diff > 0 {
      translateBy(x: 0, y: diff)
    }
  }
}
