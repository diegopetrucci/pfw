import ArgumentParser
import Darwin
import Foundation
import InlineSnapshotTesting
@testable import pfw

func assertCommand(
  _ arguments: [String],
  stdout expected: (() -> String)? = nil,
  fileID: StaticString = #fileID,
  file: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) async throws {
  let output = try await withCapturedStdout {
    var command = try PFW.parseAsRoot(arguments) as! AsyncParsableCommand
    try await command.run()
  }
  assertInlineSnapshot(
    of: output,
    as: .lines,
    syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
      trailingClosureLabel: "stdout",
      trailingClosureOffset: 1
    ),
    matches: expected,
    fileID: fileID,
    file: file,
    line: line,
    column: column
  )
}

func assertCommandThrows(
  _ arguments: [String],
  stderr: (() -> String)? = nil,
  error: (() -> String)? = nil,
  fileID: StaticString = #fileID,
  file: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) async {
  var thrownError: Error?
  let output = await withCapturedStderr {
    do {
      var command = try PFW.parseAsRoot(arguments) as! AsyncParsableCommand
      try await command.run()
    } catch {
      thrownError = error
    }
  }

  guard let thrownError else {
    preconditionFailure("Expected command to throw.")
  }

  if let stderr {
    assertInlineSnapshot(
      of: output,
      as: .lines,
      syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
        trailingClosureLabel: "stderr",
        trailingClosureOffset: 1
      ),
      matches: stderr,
      fileID: fileID,
      file: file,
      line: line,
      column: column
    )
  } else if let error {
    assertInlineSnapshot(
      of: String(describing: thrownError),
      as: .lines,
      syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
        trailingClosureLabel: "error",
        trailingClosureOffset: 1
      ),
      matches: error,
      fileID: fileID,
      file: file,
      line: line,
      column: column
    )
  } else {
    preconditionFailure("Provide a stderr or error snapshot closure.")
  }
}

func withCapturedStdout(_ body: () async throws -> Void) async rethrows -> String {
  let pipe = Pipe()
  let original = dup(STDOUT_FILENO)
  fflush(stdout)
  dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)

  try await body()

  fflush(stdout)
  // Restore stdout before closing the pipe's write end, or reads can hang.
  dup2(original, STDOUT_FILENO)
  close(original)
  pipe.fileHandleForWriting.closeFile()
  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}

func withCapturedStderr(_ body: () async throws -> Void) async rethrows -> String {
  let pipe = Pipe()
  let original = dup(STDERR_FILENO)
  fflush(stderr)
  dup2(pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)

  try await body()

  fflush(stderr)
  // Restore stderr before closing the pipe's write end, or reads can hang.
  dup2(original, STDERR_FILENO)
  close(original)
  pipe.fileHandleForWriting.closeFile()
  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}
