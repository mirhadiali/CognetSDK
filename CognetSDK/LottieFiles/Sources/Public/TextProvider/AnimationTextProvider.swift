//
//  AnimationImageProvider.swift
//  Lottie_iOS
//
//  Created by Alexandr Goncharov on 07/06/2019.
//

// MARK: - AnimationKeypathTextProvider

/// Protocol for providing dynamic text to for a Lottie animation.
protocol AnimationKeypathTextProvider: AnyObject {
  /// The text to display for the given `AnimationKeypath`.
  /// If `nil` is returned, continues using the existing default text value.
  func text(for keypath: AnimationKeypath, sourceText: String) -> String?
}

// MARK: - AnimationKeypathTextProvider

/// Legacy protocol for providing dynamic text for a Lottie animation.
/// Instead prefer conforming to `AnimationKeypathTextProvider`.
@available(*, deprecated, message: """
  `AnimationKeypathTextProvider` has been deprecated and renamed to `LegacyAnimationTextProvider`. \
  Instead, conform to `AnimationKeypathTextProvider` instead or conform to `LegacyAnimationTextProvider` explicitly.
  """)
typealias AnimationTextProvider = LegacyAnimationTextProvider

// MARK: - LegacyAnimationTextProvider

/// Legacy protocol for providing dynamic text for a Lottie animation.
/// Instead prefer conforming to `AnimationKeypathTextProvider`.
protocol LegacyAnimationTextProvider: AnimationKeypathTextProvider {
  /// Legacy method to look up the text to display for the given keypath.
  /// Instead, prefer implementing `AnimationKeypathTextProvider.`
  /// The behavior of this method depends on the current rendering engine:
  ///  - The Core Animation rendering engine always calls this method
  ///    with the full keypath (e.g. `MY_LAYER.text_value`).
  ///  - The Main Thread rendering engine always calls this method
  ///    with the final component of the key path (e.g. just `text_value`).
  func textFor(keypathName: String, sourceText: String) -> String
}

extension LegacyAnimationTextProvider {
  func text(for _: AnimationKeypath, sourceText _: String) -> String? {
    nil
  }
}

// MARK: - DictionaryTextProvider

/// Text provider that simply map values from dictionary.
///  - The dictionary keys can either be the full layer keypath string (e.g. `MY_LAYER.text_value`)
///    or simply the final path component of the keypath (e.g. `text_value`).
final class DictionaryTextProvider: AnimationKeypathTextProvider, LegacyAnimationTextProvider {

  // MARK: Lifecycle

  init(_ values: [String: String]) {
    self.values = values
  }

  // MARK: Public

  func text(for keypath: AnimationKeypath, sourceText: String) -> String? {
    if let valueForFullKeypath = values[keypath.fullPath] {
      valueForFullKeypath
    }

    else if
      let lastKeypathComponent = keypath.keys.last,
      let valueForLastComponent = values[lastKeypathComponent]
    {
      valueForLastComponent
    }

    else {
      sourceText
    }
  }

  /// Never called directly by Lottie, but we continue to implement this conformance for backwards compatibility.
  func textFor(keypathName: String, sourceText: String) -> String {
    values[keypathName] ?? sourceText
  }

  // MARK: Internal

  let values: [String: String]
}

// MARK: Equatable

extension DictionaryTextProvider: Equatable {
  static func ==(_ lhs: DictionaryTextProvider, _ rhs: DictionaryTextProvider) -> Bool {
    lhs.values == rhs.values
  }
}

// MARK: - DefaultTextProvider

/// Default text provider. Uses text in the animation file
final class DefaultTextProvider: AnimationKeypathTextProvider, LegacyAnimationTextProvider {

  // MARK: Lifecycle

  init() { }

  // MARK: Public

  func textFor(keypathName _: String, sourceText: String) -> String {
    sourceText
  }

  func text(for _: AnimationKeypath, sourceText: String) -> String {
    sourceText
  }
}

// MARK: Equatable

extension DefaultTextProvider: Equatable {
  static func ==(_: DefaultTextProvider, _: DefaultTextProvider) -> Bool {
    true
  }
}
