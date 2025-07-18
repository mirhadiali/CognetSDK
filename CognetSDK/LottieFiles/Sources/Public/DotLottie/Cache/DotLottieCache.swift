//
//  LRUDotLottieCache.swift
//  Lottie
//
//  Created by Evandro Hoffmann on 20/10/22.
//

import Foundation

// MARK: - DotLottieCache

/// A DotLottie Cache that will store lottie files up to `cacheSize`.
///
/// Once `cacheSize` is reached, the least recently used lottie will be ejected.
/// The default size of the cache is 100.
class DotLottieCache: DotLottieCacheProvider {

  // MARK: Lifecycle

  init() {
    cache.countLimit = Self.defaultCacheCountLimit
  }

  // MARK: Public

  /// The global shared Cache.
  static let sharedCache = DotLottieCache()

  /// The size of the cache.
  var cacheSize = defaultCacheCountLimit {
    didSet {
      cache.countLimit = cacheSize
    }
  }

  /// Clears the Cache.
  func clearCache() {
    cache.removeAllValues()
  }

  func file(forKey key: String) -> DotLottieFile? {
    cache.value(forKey: key)
  }

  func setFile(_ lottie: DotLottieFile, forKey key: String) {
    cache.setValue(lottie, forKey: key)
  }

  // MARK: Private

  private static let defaultCacheCountLimit = 100

  /// The underlying storage of this cache.
  ///  - We use the `LRUCache` library instead of `NSCache`, because `NSCache`
  ///    clears all cached values when the app is backgrounded instead of
  ///    only when the app receives a memory warning notification.
  private var cache = LRUCache<String, DotLottieFile>()

}

// MARK: @unchecked Sendable

// DotLottieCacheProvider has a Sendable requirement, but we can't
// redesign DotLottieCache to be properly Sendable without making breaking changes.
// swiftlint:disable:next no_unchecked_sendable
extension DotLottieCache: @unchecked Sendable { }
