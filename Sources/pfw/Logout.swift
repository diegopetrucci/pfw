import ArgumentParser
import Dependencies
import Foundation

struct Logout: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Log out and remove the stored token."
  )

  func run() throws {
    @Dependency(\.fileSystem) var fileSystem
    do {
      try fileSystem.removeItem(at: tokenURL)
      print("Removed token at \(tokenURL.path).")
    } catch {
      print("No token found.")
    }
  }
}
