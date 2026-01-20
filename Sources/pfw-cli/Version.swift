import ArgumentParser
import Foundation

struct Version: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Print the pfw CLI version."
  )

  func run() throws {
    print(PFWVersion.current)
  }
}

enum PFWVersion {
  static var current: String {
    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
      !version.isEmpty
    {
      return version
    }
    if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
      !build.isEmpty
    {
      return build
    }
    if let env = ProcessInfo.processInfo.environment["PFW_VERSION"], !env.isEmpty {
      return env
    }
    return "unknown"
  }
}
