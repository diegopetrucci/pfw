@testable import pfw

struct TestWhoAmI: WhoAmI {
  var value: String

  init(_ value: String) {
    self.value = value
  }

  func callAsFunction() -> String {
    value
  }
}
