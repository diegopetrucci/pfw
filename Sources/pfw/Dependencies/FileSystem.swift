import ConcurrencyExtras
import Dependencies
import Foundation
import ZIPFoundation

protocol FileSystem: Sendable {
  var homeDirectoryForCurrentUser: URL { get }
  func createDirectory(
    at url: URL,
    withIntermediateDirectories createIntermediates: Bool,
    attributes: [FileAttributeKey: Any]?
  ) throws
  func removeItem(at url: URL) throws
  func fileExists(atPath path: String) -> Bool
  func write(_ data: Data, to url: URL) throws
  func data(at url: URL) throws -> Data
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
  func write(_ data: Data, to url: URL) throws {
    try data.write(to: url)
  }

  func data(at url: URL) throws -> Data {
    try Data(contentsOf: url)
  }
}

final class InMemoryFileSystem: FileSystem {
  enum Error: Swift.Error, Equatable {
    case directoryNotFound(String)
    case fileNotFound(String)
  }

  struct State {
    var files: [String: Data]
    var directories: Set<String>
    var homeDirectoryForCurrentUser: URL
  }

  let state: LockIsolated<State>

  init(
    homeDirectoryForCurrentUser: URL = URL(fileURLWithPath: "/Users/blob"),
    files: [String: Data] = [:],
    directories: Set<String> = []
  ) {
    let state = State(
      files: files,
      directories: directories,
      homeDirectoryForCurrentUser: homeDirectoryForCurrentUser
    )
    self.state = LockIsolated(state)
    self.state.withValue {
      _ = $0.directories.insert(normalize(homeDirectoryForCurrentUser))
    }
  }

  var filePaths: Set<String> {
    state.withValue { Set($0.files.keys) }
  }

  func setFile(_ data: Data = Data(), atPath path: String) {
    state.withValue { $0.files[normalize(path)] = data }
  }

  func createDirectory(
    at url: URL,
    withIntermediateDirectories createIntermediates: Bool,
    attributes: [FileAttributeKey: Any]?
  ) throws {
    let path = normalize(url)
    state.withValue { state in
      if createIntermediates {
        for directory in pathPrefixes(path) {
          state.directories.insert(directory)
        }
      } else {
        state.directories.insert(path)
      }
    }
  }

  func removeItem(at url: URL) throws {
    let path = normalize(url)
    state.withValue { state in
      state.files.removeValue(forKey: path)
      state.directories.remove(path)

      let prefix = path.hasSuffix("/") ? path : path + "/"
      state.files = state.files.filter { key, _ in
        !key.hasPrefix(prefix)
      }
      state.directories = state.directories.filter { directory in
        !directory.hasPrefix(prefix)
      }
    }
  }

  func fileExists(atPath path: String) -> Bool {
    let normalizedPath = normalize(path)
    return state.withValue { state in
      state.files[normalizedPath] != nil || state.directories.contains(normalizedPath)
    }
  }

  func unzipItem(
    at sourceURL: URL,
    to destinationURL: URL,
    skipCRC32: Bool,
    allowUncontainedSymlinks: Bool,
    progress: Progress?,
    pathEncoding: String.Encoding?
  ) throws {
    fatalError("unzipItem is not implemented in InMemoryFileSystem.")
  }

  var homeDirectoryForCurrentUser: URL {
    state.withValue { $0.homeDirectoryForCurrentUser }
  }

  func write(_ data: Data, to url: URL) throws {
    let path = normalize(url)
    let directory = normalize((path as NSString).deletingLastPathComponent)
    try state.withValue { state in
      guard state.directories.contains(directory) else {
        throw Error.directoryNotFound(directory)
      }
      state.files[path] = data
    }
  }

  func data(at url: URL) throws -> Data {
    let path = normalize(url)
    return try state.withValue { state in
      guard let data = state.files[path] else {
        throw Error.fileNotFound(path)
      }
      return data
    }
  }
}

enum FileSystemKey: DependencyKey {
  static let liveValue: any FileSystem = FileManager.default
  static let testValue: any FileSystem = InMemoryFileSystem()
}

extension DependencyValues {
  var fileSystem: any FileSystem {
    get { self[FileSystemKey.self] }
    set { self[FileSystemKey.self] = newValue }
  }
}

private func normalize(_ url: URL) -> String {
  normalize(url.path)
}

private func normalize(_ path: String) -> String {
  let standardized = (path as NSString).standardizingPath
  if standardized == "/" {
    return standardized
  }
  return standardized.hasSuffix("/") ? String(standardized.dropLast()) : standardized
}

private func pathPrefixes(_ path: String) -> [String] {
  let components = (path as NSString).pathComponents
  guard !components.isEmpty else { return [] }
  var current = ""
  var prefixes: [String] = []
  for component in components {
    if component == "/" {
      current = "/"
    } else if current == "/" {
      current += component
    } else if current.isEmpty {
      current = component
    } else {
      current += "/" + component
    }
    prefixes.append(current)
  }
  return prefixes
}
