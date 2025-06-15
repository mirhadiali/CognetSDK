//
//  GIFPlayerView.swift
//  CaptureDFH
//
//  Created by Khalil Charkas on 11/02/2025.
//


import SwiftUI
import WebKit

struct GIFPlayerView: UIViewRepresentable {
    let gifName: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.isOpaque = false
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let path = Bundle.main.path(forResource: gifName, ofType: "gif") {
            let url = URL(fileURLWithPath: path)
            let data = try? Data(contentsOf: url)
            let base64String = data?.base64EncodedString() ?? ""
            let html = """
            <html>
            <body style="margin:0;padding:0;background:transparent;">
            <img src="data:image/gif;base64,\(base64String)" style="width:100%;height:100%;" />
            </body>
            </html>
            """
            uiView.loadHTMLString(html, baseURL: nil)
            uiView.layer.cornerRadius = 20.0
            uiView.backgroundColor = .clear
            uiView.clipsToBounds  = true
        }
    }
}
#if DEBUG
#Preview {
    GIFPlayerView(gifName: "successTick")
        .cornerRadius(20)
        .frame(width: 250, height: 200) // Set
        
}
#endif
