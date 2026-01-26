import Dependencies
import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

protocol PointFreeServer: Sendable {
  func downloadSkills(token: String, machine: UUID, whoami: String) async throws -> Data
}

enum PointFreeServerError: Swift.Error, Equatable {
  case notLoggedIn(String?)
  case serverError(String?)
  case invalidResponse
}

struct LivePointFreeServer: PointFreeServer {
  func downloadSkills(token: String, machine: UUID, whoami: String) async throws -> Data {
    let url = URL(
      string:
        "\(URL.baseURL)/account/the-way/download?token=\(token)&machine=\(machine)&whoami=\(whoami)"
    )!
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw PointFreeServerError.invalidResponse
    }

    switch httpResponse.statusCode {
    case 200:
      return data
    case 401, 403:
      throw PointFreeServerError.notLoggedIn(String(decoding: data, as: UTF8.self))
    default:
      throw PointFreeServerError.serverError(String(decoding: data, as: UTF8.self))
    }
  }
}

actor InMemoryPointFreeServer: PointFreeServer {
  @Dependency(\.continuousClock) var clock
  var results: [Result<Data, PointFreeServerError>] = []

  init(results: [Result<Data, PointFreeServerError>]) {
    self.results = results
  }

  init(result: Result<Data, PointFreeServerError>) {
    self.results = [result]
  }

  func downloadSkills(token: String, machine: UUID, whoami: String) async throws -> Data {
    guard !results.isEmpty
    else {
      throw PointFreeServerError.invalidResponse
    }
    let result = results.removeFirst()
    if !results.isEmpty {
      try await clock.sleep(for: .seconds(1))
    }
    return try result.get()
  }
}

enum PointFreeServerKey: DependencyKey {
  static var liveValue: any PointFreeServer { LivePointFreeServer() }
  static var testValue: any PointFreeServer {
    InMemoryPointFreeServer(result: .failure(.invalidResponse))
  }
}

extension DependencyValues {
  var pointFreeServer: any PointFreeServer {
    get { self[PointFreeServerKey.self] }
    set { self[PointFreeServerKey.self] = newValue }
  }
}
