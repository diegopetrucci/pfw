#if canImport(Network)
import ArgumentParser
import Dependencies
import Foundation
import Synchronization

  import Network


protocol Auth: Sendable {
  func start() async throws -> URL
  func waitForToken() async throws -> String
}

private enum AuthKey: DependencyKey {
  static var liveValue: any Auth { try! LocalAuthServer() }
}

extension DependencyValues {
  var auth: any Auth {
    get { self[AuthKey.self] }
    set { self[AuthKey.self] = newValue }
  }
}

  actor LocalAuthServer: Auth {
    private let listener: NWListener
    private let queue = DispatchQueue(label: "pfw.auth.server")
    private var tokenContinuation: CheckedContinuation<String, Error>?

    init() throws {
      listener = try NWListener(using: .tcp, on: .any)
    }

    func start() async throws -> URL {
      let hasStarted = Mutex(false)
      listener.stateUpdateHandler = { state in
        guard state == .ready
        else { return }
        hasStarted.withLock { $0 = true }
      }
      listener.newConnectionHandler = { [weak self] connection in
        Task {
          connection.start(queue: self?.queue ?? .main)
          await self?.receiveToken(from: connection)
        }
      }
      listener.start(queue: queue)
      while !hasStarted.withLock(\.self) {
        try await Task.sleep(for: .seconds(0.1))
        // TODO: Timeout if takes too long
      }
      guard let port = listener.port else {
        throw ValidationError("Unable to determine callback port.")
      }
      return URL(string: "http://127.0.0.1:\(port)/callback")!
    }

    func waitForToken() async throws -> String {
      try await withCheckedThrowingContinuation { continuation in
        tokenContinuation = continuation
      }
    }

    private func receiveToken(from connection: NWConnection) {
      connection.receive(minimumIncompleteLength: 1, maximumLength: 8_192) {
        [weak self] data, _, _, error in
        Task {
          if let error {
            await self?.finish(with: .failure(error))
            connection.cancel()
            return
          }
          guard let data, let request = String(data: data, encoding: .utf8) else {
            await self?.finish(with: .failure(ValidationError("Invalid request.")))
            connection.cancel()
            return
          }
          let token = Self.token(from: request)
          if let token {
            await self?.respond(connection: connection, success: true)
            await self?.finish(with: .success(token))
          } else {
            await self?.respond(connection: connection, success: false)
            await self?.finish(with: .failure(ValidationError("Missing token in redirect.")))
          }
          connection.cancel()
        }
      }
    }

    private func respond(connection: NWConnection, success: Bool) {
      let message =
        success
        ? "You can return to the terminal. Login complete."
        : "Login failed. Please return to the terminal."
      let body = "<html><body><p>\(message)</p></body></html>"
      let response = """
        HTTP/1.1 200 OK\r
        Content-Type: text/html; charset=utf-8\r
        Content-Length: \(body.utf8.count)\r
        Connection: close\r
        \r
        \(body)
        """
      connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in })
    }

    private func finish(with result: Result<String, Error>) {
      tokenContinuation?.resume(with: result)
      tokenContinuation = nil
      listener.cancel()
    }

    private static func token(from request: String) -> String? {
      return String(
        request
          .dropFirst("GET /callback?token=".count)
          .prefix(while: { $0 != " " })
      )
    }
  }

#endif
