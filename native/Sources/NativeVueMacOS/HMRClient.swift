import Foundation

final class HMRClient: NSObject, URLSessionWebSocketDelegate {
    private var session: URLSession!
    private var task: URLSessionWebSocketTask?
    private let onUpdate: @MainActor (String) -> Void
    private let onError: @MainActor (String) -> Void

    init(onUpdate: @escaping @MainActor (String) -> Void, onError: @escaping @MainActor (String) -> Void) {
        self.onUpdate = onUpdate
        self.onError = onError
        super.init()
        session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
    }

    func connect(to url: URL) {
        let task = session.webSocketTask(with: url)
        self.task = task
        task.resume()
        receive()
    }

    func disconnect() {
        task?.cancel(with: .goingAway, reason: nil)
        session.invalidateAndCancel()
    }

    private func receive() {
        task?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                Task { @MainActor in self.onError("HMR connection failed: \(error.localizedDescription)") }
            case .success(let message):
                let text: String
                switch message {
                case .string(let value): text = value
                case .data(let data): text = String(decoding: data, as: UTF8.self)
                @unknown default: text = ""
                }
                self.handle(text)
                self.receive()
            }
        }
    }

    private func handle(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }
        if type == "update", let code = json["code"] as? String {
            Task { @MainActor in self.onUpdate(code) }
        } else if type == "error", let message = json["message"] as? String {
            Task { @MainActor in self.onError(message) }
        }
    }
}
