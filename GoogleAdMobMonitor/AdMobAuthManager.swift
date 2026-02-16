import Foundation
import GoogleSignIn
import UIKit

final class AdMobAuthManager {
  private let clientID = "974734396380-uoj0bbfdj2r7prlu5p1nim3h3dq53vhq.apps.googleusercontent.com"
  private let scopes = ["https://www.googleapis.com/auth/admob.readonly"]

  var hasPreviousSignIn: Bool {
    GIDSignIn.sharedInstance.hasPreviousSignIn()
  }

  func restorePreviousSignIn() async throws {
    _ = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
    try await ensureScopes()
  }

  @MainActor
  func signInInteractive() async throws {
    guard let rootVC = UIApplication.shared.firstKeyWindowRootViewController else {
      throw NSError(domain: "Auth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to find a root view controller for Google Sign-In."])
    }

    let config = GIDConfiguration(clientID: clientID)
    GIDSignIn.sharedInstance.configuration = config
    _ = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC, hint: nil, additionalScopes: scopes)
  }

  func accessToken() async throws -> String {
    guard let token = GIDSignIn.sharedInstance.currentUser?.accessToken.tokenString else {
      throw NSError(domain: "Auth", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing access token. Please sign in again."])
    }
    return token
  }

  func signOut() {
    GIDSignIn.sharedInstance.signOut()
  }

  @MainActor
  private func ensureScopes() async throws {
    guard let rootVC = UIApplication.shared.firstKeyWindowRootViewController else { return }
    let user = GIDSignIn.sharedInstance.currentUser
    if let user, !scopes.allSatisfy({ user.grantedScopes?.contains($0) == true }) {
      _ = try await user.addScopes(scopes, presenting: rootVC)
    }
  }
}

@MainActor
private extension UIApplication {
  var firstKeyWindowRootViewController: UIViewController? {
    connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first(where: { $0.isKeyWindow })?
      .rootViewController
  }
}
