import Dependencies
import Foundation
import ZIPFoundation

protocol FileSystem: Sendable {
  var homeDirectoryForCurrentUser: URL { get }
  static var temporaryDirectory: URL { get }
  func createDirectory(
    at url: URL,
    withIntermediateDirectories createIntermediates: Bool,
    attributes: [FileAttributeKey: Any]?
  ) throws
  func removeItem(at url: URL) throws
  func fileExists(atPath path: String) -> Bool
  func write(_ data: Data, to url: URL) throws
  func data(at url: URL) throws -> Data
  func createSymbolicLink(at url: URL, withDestinationURL destURL: URL) throws
  func unzipItem(
    at sourceURL: URL,
    to destinationURL: URL,
    skipCRC32: Bool,
    allowUncontainedSymlinks: Bool,
    progress: Progress?,
    pathEncoding: String.Encoding?
  ) throws
}

extension FileSystem {
  func createDirectory(
    at url: URL,
    withIntermediateDirectories createIntermediates: Bool
  ) throws {
    try createDirectory(at: url, withIntermediateDirectories: createIntermediates, attributes: nil)
  }

  func unzipItem(at sourceURL: URL, to destinationURL: URL) throws {
    try unzipItem(
      at: sourceURL,
      to: destinationURL,
      skipCRC32: false,
      allowUncontainedSymlinks: false,
      progress: nil,
      pathEncoding: nil
    )
  }
}

extension FileManager: FileSystem {
  static var temporaryDirectory: URL {
    URL.temporaryDirectory
  }

  func write(_ data: Data, to url: URL) throws {
    try data.write(to: url)
  }

  func data(at url: URL) throws -> Data {
    try Data(contentsOf: url)
  }
}

enum FileSystemKey: DependencyKey {
  static var liveValue: any FileSystem { FileManager.default }
}

extension DependencyValues {
  var fileSystem: any FileSystem {
    get { self[FileSystemKey.self] }
    set { self[FileSystemKey.self] = newValue }
  }
}
