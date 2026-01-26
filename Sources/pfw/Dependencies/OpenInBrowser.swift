import Dependencies
import Foundation

protocol OpenInBrowser: Sendable {
  func callAsFunction(_ url: URL) throws
}

struct LiveOpenInBrowser: OpenInBrowser {
  func callAsFunction(_ url: URL) throws {
    #if os(macOS)
      let process = Process()
      process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
      process.arguments = [url.absoluteString]
      try process.run()
    #elseif os(Linux)
      let process = Process()
      process.executableURL = URL(fileURLWithPath: "/usr/bin/xdg-open")
      process.arguments = [url.absoluteString]
      try process.run()
    #else
      print("Please open this URL in your browser: \(url.absoluteString)")
    #endif
  }
}

enum OpenInBrowserKey: DependencyKey {
  static var liveValue: any OpenInBrowser { LiveOpenInBrowser() }
}

extension DependencyValues {
  var openInBrowser: any OpenInBrowser {
    get { self[OpenInBrowserKey.self] }
    set { self[OpenInBrowserKey.self] = newValue }
  }
}
