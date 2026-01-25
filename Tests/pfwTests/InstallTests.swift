import InlineSnapshotTesting
import Testing
@testable import pfw

@Suite struct InstallTests {
  @Test func basics() async throws {
    try await assertCommand(["install", "--tool", "claude"])
  }
}
