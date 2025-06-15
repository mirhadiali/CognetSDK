

import SwiftUI

struct LoaderView: View {
    var body: some View {
        VStack {
            ProgressView() // SwiftUI's built-in activity indicator
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5) // Adjust size
                .padding(20)
        }
        .background(Color.black.opacity(0.5)) // Dim background
        .cornerRadius(10)
        .frame(width: 100, height: 100)
    }
}

import Combine

class LoaderViewModel: ObservableObject {
    @Published var isLoading: Bool = false

    func showLoader() {
        DispatchQueue.main.async {
            self.isLoading = true
        }
    }

    func hideLoader() {
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
}

struct AnotherView: View {
    @EnvironmentObject var loaderVM: LoaderViewModel

    var body: some View {
        ZStack {
            Text("Another View Content")
                .onTapGesture {
                    loaderVM.isLoading.toggle()
                }

            if loaderVM.isLoading {
                LoaderView()
            }
        }
    }
}
#if DEBUG
#Preview {
    AnotherView()
        .environmentObject(LoaderViewModel())
}
#endif
