import ArgumentParser
import Foundation

struct Logout: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Log out and remove the stored token."
  )

  @Flag(help: "Remove all stored data, including downloaded skills.")
  var clean = false

  func run() throws {
    if clean {
      if FileManager.default.fileExists(atPath: pfwDirectoryURL.path) {
        try FileManager.default.removeItem(at: pfwDirectoryURL)
        print("Removed data at \(pfwDirectoryURL.path).")
      } else {
        print("No data found.")
      }
      return
    }

    if FileManager.default.fileExists(atPath: tokenURL.path) {
      try FileManager.default.removeItem(at: tokenURL)
      print("Removed token at \(tokenURL.path).")
      return
    }
    print("No token found.")
  }
}
