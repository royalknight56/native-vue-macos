import Foundation
import JavaScriptCore

@MainActor
final class TimerRegistry: NSObject {
    private weak var virtualMachine: JSVirtualMachine?
    private var callbacks: [Int: JSManagedValue] = [:]
    private var nextID = 1

    init(virtualMachine: JSVirtualMachine) {
        self.virtualMachine = virtualMachine
    }

    func schedule(_ callback: JSValue, delayMilliseconds: Double) -> Int {
        let id = nextID
        nextID += 1
        let managed = JSManagedValue(value: callback)
        callbacks[id] = managed
        virtualMachine?.addManagedReference(managed, withOwner: self)
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0, delayMilliseconds) / 1_000) { [weak self] in
            guard let self, let callback = self.callbacks[id]?.value else { return }
            callback.call(withArguments: [])
            self.clear(id)
        }
        return id
    }

    func clear(_ id: Int) {
        guard let managed = callbacks.removeValue(forKey: id) else { return }
        virtualMachine?.removeManagedReference(managed, withOwner: self)
    }

    func dispose() {
        for id in callbacks.keys { clear(id) }
    }
}
