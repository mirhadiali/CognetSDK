//
//  DocumentType.swift
//  CaptureFace
//
//  Created by Hadi Ali on 21/04/2025.
//


import SwiftUI

enum DocumentType {
    case passport
    case idCard
    
    func getSharpnessThreshold() -> CGFloat {
        switch self {
        case .passport:
            0.018
        case .idCard:
            0.011
        }
    }
    
    func getTitle() -> String {
        switch self {
        case .passport:
            "Passport"
        case .idCard:
            "ID Card"
        }
    }
}

struct DocumentToggleView: View {
    @Binding var selected: DocumentType

    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                selected = .passport
            }) {
                HStack(spacing: 8) {
                    if selected == .passport {
                        Image(systemName: "checkmark")
                    }
                    Text("Passport")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selected == .passport ? Color(hex: "#3C74F6") : Color.clear)
            }

            Button(action: {
                selected = .idCard
            }) {
                HStack(spacing: 8) {
                    if selected == .idCard {
                        Image(systemName: "checkmark")
                    }
                    Text("ID Card")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selected == .idCard ? Color(hex: "#3C74F6") : Color.clear)
            }
        }
        .frame(height: 45)
        .background(Color.appGreen)
        .clipShape(Capsule())
        
        .overlay(
            Capsule()
                .stroke(Color.white, lineWidth: 1.5)
        )
        .padding(.horizontal)
    }
}
struct ToggleContentView: View {
    @State private var selectedType: DocumentType = .idCard

    var body: some View {
        DocumentToggleView(selected: $selectedType)
    }
}
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }
}
#if DEBUG
#Preview {
    ToggleContentView()
}
#endif
