import InlineSnapshotTesting
import Testing
@testable import pfw

extension BaseSuite {
  @Suite struct InstallTests {
    @Test func basics() async throws {
      try await assertCommand(["install", "--tool", "claude"])
    }
  }
}
