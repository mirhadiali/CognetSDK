//
//  PreCompositionLayer.swift
//  lottie-swift
//
//  Created by Brandon Withrow on 1/25/19.
//

import QuartzCore

final class PreCompositionLayer: CompositionLayer {

  // MARK: Lifecycle

  init(
    precomp: PreCompLayerModel,
    asset: PrecompAsset,
    layerImageProvider: LayerImageProvider,
    layerTextProvider: LayerTextProvider,
    layerFontProvider: LayerFontProvider,
    textProvider: AnimationKeypathTextProvider,
    fontProvider: AnimationFontProvider,
    assetLibrary: AssetLibrary?,
    frameRate: CGFloat,
    rootAnimationLayer: MainThreadAnimationLayer?)
  {
    animationLayers = []
    if let keyframes = precomp.timeRemapping?.keyframes {
      remappingNode = NodeProperty(provider: KeyframeInterpolator(keyframes: keyframes))
    } else {
      remappingNode = nil
    }
    self.frameRate = frameRate
    super.init(layer: precomp, size: CGSize(width: precomp.width, height: precomp.height))
    bounds = CGRect(origin: .zero, size: CGSize(width: precomp.width, height: precomp.height))
    contentsLayer.masksToBounds = true
    contentsLayer.bounds = bounds

    let layers = asset.layers.initializeCompositionLayers(
      assetLibrary: assetLibrary,
      layerImageProvider: layerImageProvider,
      layerTextProvider: layerTextProvider,
      layerFontProvider: layerFontProvider,
      textProvider: textProvider,
      fontProvider: fontProvider,
      frameRate: frameRate,
      rootAnimationLayer: rootAnimationLayer)

    var imageLayers = [ImageCompositionLayer]()
    var textLayers = [TextCompositionLayer]()

    var mattedLayer: CompositionLayer? = nil

    for layer in layers.reversed() {
      layer.bounds = bounds
      animationLayers.append(layer)
      if let imageLayer = layer as? ImageCompositionLayer {
        imageLayers.append(imageLayer)
      }
      if let textLayer = layer as? TextCompositionLayer {
        textLayers.append(textLayer)
      }
      if let matte = mattedLayer {
        /// The previous layer requires this layer to be its matte
        matte.matteLayer = layer
        mattedLayer = nil
        continue
      }
      if
        let matte = layer.matteType,
        matte == .add || matte == .invert
      {
        /// We have a layer that requires a matte.
        mattedLayer = layer
      }
      contentsLayer.addSublayer(layer)
    }

    childKeypaths.append(contentsOf: layers)

    layerImageProvider.addImageLayers(imageLayers)
    layerTextProvider.addTextLayers(textLayers)
    layerFontProvider.addTextLayers(textLayers)
  }

  override init(layer: Any) {
    /// Used for creating shadow model layers. Read More here: https://developer.apple.com/documentation/quartzcore/calayer/1410842-init
    guard let layer = layer as? PreCompositionLayer else {
      fatalError("init(layer:) Wrong Layer Class")
    }
    frameRate = layer.frameRate
    remappingNode = nil
    animationLayers = []

    super.init(layer: layer)
  }

  required public init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  let frameRate: CGFloat
  let remappingNode: NodeProperty<LottieVector1D>?

  override var keypathProperties: [String: AnyNodeProperty] {
    guard let remappingNode else {
      return super.keypathProperties
    }
    return ["Time Remap": remappingNode]
  }

  override func displayContentsWithFrame(frame: CGFloat, forceUpdates: Bool) {
    let localFrame: CGFloat
    if let remappingNode {
      remappingNode.update(frame: frame)
      localFrame = remappingNode.value.cgFloatValue * frameRate
    } else {
      localFrame = (frame - startFrame) / timeStretch
    }
    for animationLayer in animationLayers {
      animationLayer.displayWithFrame(frame: localFrame, forceUpdates: forceUpdates)
    }
  }

  override func updateRenderScale() {
    super.updateRenderScale()
    for animationLayer in animationLayers {
      animationLayer.renderScale = renderScale
    }
  }

  // MARK: Fileprivate

  fileprivate var animationLayers: [CompositionLayer]
}
