
import SwiftUI

struct CommonAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let action: (() -> Void)?

    func body(content: Content) -> some View {
        content.alert(isPresented: $isPresented) {
            Alert(
                title: Text(title),
                message: Text(message),
                dismissButton: .default(Text("OK"), action: {
                    action?()
                })
            )
        }
    }
}

extension View {
    func commonAlert(
        isPresented: Binding<Bool>,
        alert: AlertViewModel
    ) -> some View {
        self.modifier(CommonAlertModifier(
            isPresented: isPresented,
            title: alert.alertTitle,
            message: alert.alertMessage,
            action: alert.alertAction
        ))
    }
}

struct AlertViewModel {
     var alertTitle: String = ""
     var alertMessage: String = ""
     var alertAction: (() -> Void)? = nil
}

struct AlertSampleView: View {
    @State private var showAlert = false

    var body: some View {
        VStack {
            Button("Show Alert") {
                showAlert = true
            }
        }
        .commonAlert(
            isPresented: $showAlert, alert: AlertViewModel(alertTitle: "Sample",alertMessage: "test Message")
        )
    }
}
#if DEBUG

#Preview {
    AlertSampleView()
}
#endif
