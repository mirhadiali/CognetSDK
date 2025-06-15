//
//  LottieView.swift
//  CaptureDFH
//
//  Created by Khalil Charkas on 09/02/2025.
//


import SwiftUI

struct LottieViewUI: UIViewRepresentable {
    var animationName: String
    var loopMode: LottieLoopMode = .loop
    var frameSize: CGSize

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView(frame: CGRect(origin: .zero, size: frameSize))
        
        let animationView = LottieAnimationView(name: animationName)
        animationView.loopMode = loopMode
        animationView.contentMode = .scaleAspectFit
        animationView.frame = containerView.bounds
        animationView.clipsToBounds = true
        
        containerView.addSubview(animationView)
        animationView.play()
        
        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

}
