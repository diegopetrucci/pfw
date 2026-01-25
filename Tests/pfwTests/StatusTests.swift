import InlineSnapshotTesting
import Testing
@testable import pfw

extension BaseSuite {
  @Suite struct StatusTests {
    @Test func basics() async throws {
      try await assertCommand(["status"]) {
        """
        Logged in: no
        Token path: /Users/blob/.pfw/token
        Data directory: /Users/blob/.pfw
        Data directory exists: no
        Default install path (codex): /Users/blob/codex/skills/the-point-free-way
        Default install path (claude): /Users/blob/claude/skills/the-point-free-way
        """
      }
    }
  }
}
