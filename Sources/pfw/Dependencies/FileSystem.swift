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
  func unzipItem(
    at sourceURL: URL,
    to destinationURL: URL,
    skipCRC32: Bool,
    allowUncontainedSymlinks: Bool,
    progress: Progress?,
    pathEncoding: String.Encoding?
  ) throws
}

extension FileManager: FileSystem {
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

final class InMemoryFileSystem: FileSystem, @unchecked Sendable {
  private(set) var files: [String: Data]
  private(set) var directories: Set<String>
  var homeDirectoryForCurrentUser: URL

  init(
    homeDirectoryForCurrentUser: URL = URL(fileURLWithPath: "/"),
    files: [String: Data] = [:],
    directories: Set<String> = []
  ) {
    self.homeDirectoryForCurrentUser = homeDirectoryForCurrentUser
    self.files = files
    self.directories = directories
    self.directories.insert(normalize(homeDirectoryForCurrentUser))
  }

  var filePaths: Set<String> {
    Set(files.keys)
  }

  func setFile(_ data: Data = Data(), atPath path: String) {
    files[normalize(path)] = data
  }

  func createDirectory(
    at url: URL,
    withIntermediateDirectories createIntermediates: Bool,
    attributes: [FileAttributeKey: Any]?
  ) throws {
    let path = normalize(url)
    if createIntermediates {
      for directory in pathPrefixes(path) {
        directories.insert(directory)
      }
    } else {
      directories.insert(path)
    }
  }

  func removeItem(at url: URL) throws {
    let path = normalize(url)
    files.removeValue(forKey: path)
    directories.remove(path)

    let prefix = path.hasSuffix("/") ? path : path + "/"
    files = files.filter { key, _ in
      !key.hasPrefix(prefix)
    }
    directories = directories.filter { directory in
      !directory.hasPrefix(prefix)
    }
  }

  func fileExists(atPath path: String) -> Bool {
    let normalizedPath = normalize(path)
    return files[normalizedPath] != nil || directories.contains(normalizedPath)
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
