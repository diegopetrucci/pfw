import InlineSnapshotTesting
import Testing
@testable import pfw

extension BaseSuite {
  @Suite struct InstallTests {
    @Test func noToolSpecified() async throws {
      await assertCommandThrows(["install"]) {
        """
        Missing expected argument '--tool <tool>'
        """
      }
    }

    @Test func loggedOut() async throws {
      await assertCommandThrows(["install", "--tool", "codex"]) {
        """
        No token found. Run `pfw login` first.
        """
      }
    }
  }
}
