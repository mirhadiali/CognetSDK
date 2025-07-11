// Created by Cal Stephens on 7/14/23.
// Copyright © 2023 Airbnb Inc. All rights reserved.

// MARK: - RenderingEngineOption

enum RenderingEngineOption: Hashable {
  /// Uses the Core Animation engine for supported animations, and falls back to using
  /// the Main Thread engine for animations that use features not supported by the
  /// Core Animation engine.
  case automatic

  /// Uses the specified rendering engine
  case specific(RenderingEngine)

  // MARK: Public

  /// The Main Thread rendering engine, which supports all Lottie features
  /// but runs on the main thread, which comes with some CPU overhead and
  /// can cause the animation to play at a low framerate when the CPU is busy.
  static var mainThread: RenderingEngineOption { .specific(.mainThread) }

  /// The Core Animation rendering engine, that animates using Core Animation
  /// and has better performance characteristics than the Main Thread engine,
  /// but doesn't support all Lottie features.
  ///  - In general, prefer using `RenderingEngineOption.automatic` over
  ///    `RenderingEngineOption.coreAnimation`. The Core Animation rendering
  ///    engine doesn't support all features supported by the Main Thread
  ///    rendering engine. When using `RenderingEngineOption.automatic`,
  ///    Lottie will automatically fall back to the Main Thread engine
  ///    when necessary.
  static var coreAnimation: RenderingEngineOption { .specific(.coreAnimation) }
}

// MARK: - RenderingEngine

/// The rendering engine implementation to use when displaying an animation
enum RenderingEngine: Hashable {
  /// The Main Thread rendering engine, which supports all Lottie features
  /// but runs on the main thread, which comes with some CPU overhead and
  /// can cause the animation to play at a low framerate when the CPU is busy.
  case mainThread

  /// The Core Animation rendering engine, that animates using Core Animation
  /// and has better performance characteristics than the Main Thread engine,
  /// but doesn't support all Lottie features.
  case coreAnimation
}

// MARK: - RenderingEngineOption + RawRepresentable, CustomStringConvertible

extension RenderingEngineOption: RawRepresentable, CustomStringConvertible {

  // MARK: Lifecycle

  init?(rawValue: String) {
    if rawValue == "Automatic" {
      self = .automatic
    } else if let engine = RenderingEngine(rawValue: rawValue) {
      self = .specific(engine)
    } else {
      return nil
    }
  }

  // MARK: Public

  var rawValue: String {
    switch self {
    case .automatic:
      "Automatic"
    case .specific(let engine):
      engine.rawValue
    }
  }

  var description: String {
    rawValue
  }

}

// MARK: - RenderingEngine + RawRepresentable, CustomStringConvertible

extension RenderingEngine: RawRepresentable, CustomStringConvertible {

  // MARK: Lifecycle

  init?(rawValue: String) {
    switch rawValue {
    case "Main Thread":
      self = .mainThread
    case "Core Animation":
      self = .coreAnimation
    default:
      return nil
    }
  }

  // MARK: Public

  var rawValue: String {
    switch self {
    case .mainThread:
      "Main Thread"
    case .coreAnimation:
      "Core Animation"
    }
  }

  var description: String {
    rawValue
  }
}
