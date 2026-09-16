import AppKit
import Foundation
import NativeVueMacOS

@MainActor
final class ApplicationDelegate: NSObject, NSApplicationDelegate {
    private var runtime: NativeRuntime?

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            let options = try HostOptions(arguments: CommandLine.arguments)
            let runtime = NativeRuntime()
            self.runtime = runtime
            try runtime.start(runtimeURL: options.runtimeURL, applicationURL: options.bundleURL, hmrURL: options.hmrURL)
        } catch {
            fputs("[native-vue-macos] startup failed: \(error)\n", stderr)
            NSApp.terminate(nil)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        runtime?.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

struct HostOptions {
    let runtimeURL: URL
    let bundleURL: URL
    let hmrURL: URL?

    init(arguments: [String]) throws {
        var values: [String: String] = [:]
        var index = 1
        while index + 1 < arguments.count {
            if arguments[index].hasPrefix("--") {
                values[arguments[index]] = arguments[index + 1]
                index += 2
            } else {
                index += 1
            }
        }
        let resources = Bundle.main.resourceURL
        guard let runtimePath = values["--runtime"] ?? resources?.appendingPathComponent("runtime.js").path,
              let bundlePath = values["--bundle"] ?? resources?.appendingPathComponent("app.js").path else {
            throw NSError(domain: "NativeVueHost", code: 1, userInfo: [NSLocalizedDescriptionKey: "Pass --runtime and --bundle paths"])
        }
        runtimeURL = URL(fileURLWithPath: runtimePath)
        bundleURL = URL(fileURLWithPath: bundlePath)
        hmrURL = values["--hmr-url"].flatMap(URL.init(string:))
    }
}

@main
struct NativeVueHostMain {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let delegate = ApplicationDelegate()
        app.delegate = delegate
        app.run()
    }
}
