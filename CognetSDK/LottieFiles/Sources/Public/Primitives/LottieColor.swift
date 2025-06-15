//
//  LottieColor.swift
//  lottie-swift
//
//  Created by Brandon Withrow on 2/4/19.
//

// MARK: - ColorFormatDenominator

enum ColorFormatDenominator: Hashable {
  case One
  case OneHundred
  case TwoFiftyFive

  var value: Double {
    switch self {
    case .One:
      1.0
    case .OneHundred:
      100.0
    case .TwoFiftyFive:
      255.0
    }
  }
}

// MARK: - LottieColor

struct LottieColor: Hashable {

  var r: Double
  var g: Double
  var b: Double
  var a: Double

  init(r: Double, g: Double, b: Double, a: Double, denominator: ColorFormatDenominator = .One) {
    self.r = r / denominator.value
    self.g = g / denominator.value
    self.b = b / denominator.value
    self.a = a / denominator.value
  }

}
