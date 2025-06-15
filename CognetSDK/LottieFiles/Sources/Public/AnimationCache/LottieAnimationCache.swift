//
//  LottieAnimationCache.swift
//  Lottie
//
//  Created by Marcelo Fabri on 10/17/22.
//

/// A customization point to configure which `AnimationCacheProvider` will be used.
enum LottieAnimationCache {

  /// The animation cache that will be used when loading `LottieAnimation` models.
  /// Using an Animation Cache can increase performance when loading an animation multiple times.
  /// Defaults to DefaultAnimationCache.sharedCache.
  static var shared: AnimationCacheProvider? = DefaultAnimationCache.sharedCache
}
