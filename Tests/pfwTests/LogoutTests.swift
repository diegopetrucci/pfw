import ArgumentParser
import Dependencies
import DependenciesTestSupport
import Foundation
import InlineSnapshotTesting
import Testing

@testable import pfw

extension BaseSuite {
  @Suite struct LogoutTests {
    @Dependency(\.fileSystem) var fileSystem
    var inMemoryFileSystem: InMemoryFileSystem {
      fileSystem as! InMemoryFileSystem
    }

    @Test(
      .dependencies {
        $0.auth = InMemoryAuth(
          redirectURL: URL(string: "http://localhost:1234/callback"),
          token: "deadbeef"
        )
      }
    )
    func logout() async throws {
      var command = try #require(try PFW.parseAsRoot(["login"]) as? AsyncParsableCommand)
      try await command.run()

      try await assertCommand(["logout"]) {
        """
        Removed token at /Users/blob/.pfw/token.
        """
      }
      #expect(
        try String(
          decoding: fileSystem.data(at: URL(filePath: "/Users/blob/.pfw/machine")),
          as: UTF8.self
        ) == "00000000-0000-0000-0000-000000000000"
      )
    }

    @Test
    func logout_NotLoggedIn() async throws {
      try await assertCommand(["logout"]) {
        """
        No token found.
        """
      }
    }
  }
}
