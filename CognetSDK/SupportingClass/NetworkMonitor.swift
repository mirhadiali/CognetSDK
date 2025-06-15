//


import Network
import SwiftUI

class NetworkMonitor: ObservableObject {
    private var monitor: NWPathMonitor
    private var queue: DispatchQueue

    @Published var isConnected: Bool = true
    @Published var showNetworkError: Bool = false
    @Published var showNetworkErrorToast: ToastModel = ToastModel(message: "❌ No Internet Connection",duration: 5.0,code: .alert)

    static let shared = NetworkMonitor() // Singleton instance

    private init() {
        monitor = NWPathMonitor()
        queue = DispatchQueue(label: "NetworkMonitor")
        
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.showNetworkError = !(self?.isConnected ?? true)
            }
        }
        
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
