//
//  Vectors.swift
//  lottie-swift
//
//  Created by Brandon Withrow on 2/4/19.
//

// MARK: - LottieVector1D

struct LottieVector1D: Hashable, Sendable {

  init(_ value: Double) {
    self.value = value
  }

  let value: Double

}

// MARK: - LottieVector3D

/// A three dimensional vector.
/// These vectors are encoded and decoded from [Double]
struct LottieVector3D: Hashable, Sendable {

  let x: Double
  let y: Double
  let z: Double

  init(x: Double, y: Double, z: Double) {
    self.x = x
    self.y = y
    self.z = z
  }

}
