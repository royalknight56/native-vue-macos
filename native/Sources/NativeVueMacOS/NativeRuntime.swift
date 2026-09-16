import AppKit
import Foundation
import JavaScriptCore

@MainActor
public final class NativeRuntime {
    public let context: JSContext
    public let bridge: NativeBridge
    private let timers: TimerRegistry
    private var hmrClient: HMRClient?

    public convenience init() {
        self.init(registry: .shared)
    }

    public init(registry: NativeElementFactoryRegistry) {
        let virtualMachine = JSVirtualMachine()!
        context = JSContext(virtualMachine: virtualMachine)!
        bridge = NativeBridge(registry: registry)
        timers = TimerRegistry(virtualMachine: virtualMachine)
        bridge.context = context
        bridge.hotUpdateEvaluator = { [weak context] code in
            guard let context else { return false }
            context.evaluateScript(code, withSourceURL: URL(string: "native-hmr://app.js"))
            return context.exception == nil
        }
        installExceptionHandler()
        installGlobals()
    }

    public func start(runtimeURL: URL, applicationURL: URL, hmrURL: URL? = nil) throws {
        try evaluate(file: runtimeURL)
        try evaluate(file: applicationURL)
        if let hmrURL {
            let client = HMRClient(
                onUpdate: { [weak self] code in self?.applyHotUpdate(code) },
                onError: { message in fputs("[native-vue-macos] \(message)\n", stderr) }
            )
            hmrClient = client
            client.connect(to: hmrURL)
        }
    }

    public func applyHotUpdate(_ code: String) {
        context.exception = nil
        context.evaluateScript(code, withSourceURL: URL(string: "native-hmr://app.js"))
        if let exception = context.exception {
            bridge.reportError(exception.toString(), exception.objectForKeyedSubscript("stack")?.toString() ?? "")
            context.exception = nil
        }
    }

    public func stop() {
        hmrClient?.disconnect()
        hmrClient = nil
        timers.dispose()
        bridge.dispose()
    }

    private func evaluate(file url: URL) throws {
        let code = try String(contentsOf: url, encoding: .utf8)
        context.exception = nil
        context.evaluateScript(code, withSourceURL: url)
        if let exception = context.exception {
            let stack = exception.objectForKeyedSubscript("stack")?.toString() ?? ""
            context.exception = nil
            throw NSError.nativeVue("JavaScript error in \(url.lastPathComponent): \(exception.toString() ?? "unknown error")\n\(stack)")
        }
    }

    private func installExceptionHandler() {
        context.exceptionHandler = { _, exception in
            guard let exception else { return }
            let stack = exception.objectForKeyedSubscript("stack")?.toString() ?? ""
            fputs("[native-vue-macos] Unhandled JavaScript exception: \(exception)\n\(stack)\n", stderr)
        }
    }

    private func installGlobals() {
        context.setObject(bridge, forKeyedSubscript: "__nativeBridge" as NSString)

        let log: @convention(block) (JSValue) -> Void = { value in
            print(value.toString() ?? "undefined")
        }
        let warn: @convention(block) (JSValue) -> Void = { value in
            fputs("[native-vue-macos] \(value.toString() ?? "undefined")\n", stderr)
        }
        let setTimeout: @convention(block) (JSValue, Double) -> Int = { [weak timers] callback, delay in
            MainActor.assumeIsolated { timers?.schedule(callback, delayMilliseconds: delay) ?? -1 }
        }
        let clearTimeout: @convention(block) (Int) -> Void = { [weak timers] id in
            MainActor.assumeIsolated { timers?.clear(id) }
        }
        context.setObject(log, forKeyedSubscript: "__nativeLog" as NSString)
        context.setObject(warn, forKeyedSubscript: "__nativeWarn" as NSString)
        context.setObject(setTimeout, forKeyedSubscript: "__nativeSetTimeout" as NSString)
        context.setObject(clearTimeout, forKeyedSubscript: "__nativeClearTimeout" as NSString)
        context.evaluateScript("""
          globalThis.global = globalThis;
          globalThis.console = {
            log: (...values) => __nativeLog(values.map(String).join(' ')),
            info: (...values) => __nativeLog(values.map(String).join(' ')),
            warn: (...values) => __nativeWarn(values.map(String).join(' ')),
            error: (...values) => __nativeWarn(values.map(String).join(' '))
          };
          globalThis.setTimeout = __nativeSetTimeout;
          globalThis.clearTimeout = __nativeClearTimeout;
          globalThis.queueMicrotask = callback => Promise.resolve().then(callback);
        """)
    }
}
