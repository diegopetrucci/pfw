import InlineSnapshotTesting
import Testing
@testable import pfw

extension BaseSuite {
  @Suite struct StatusTests {
    @Test func basics() async throws {
      try await assertCommand(["status"]) {
      """
      Logged in: yes
      Token path: /Users/brandon/.pfw/token
      Data directory: /Users/brandon/.pfw
      Data directory exists: yes
      Default install path (codex): /Users/brandon/.codex/skills/the-point-free-way
      Default install path (claude): /Users/brandon/.claude/skills/the-point-free-way
      """
      }
    }
  }
}
