import Foundation

@MainActor
final class StatsViewModel: ObservableObject {
  @Published private(set) var isSignedIn = false
  @Published private(set) var isLoading = false
  @Published private(set) var report: DetailedReport?
  @Published var errorMessage: String?
  @Published var selectedDateRange: DateRangeOption = .monthToDate

  private let auth = AdMobAuthManager()
  private let api = AdMobAPIClient()

  func restorePreviousSignInIfPossible() async {
    do {
      isSignedIn = auth.hasPreviousSignIn
      if isSignedIn {
        try await auth.restorePreviousSignIn()
        await refresh()
      }
    } catch {
      errorMessage = error.localizedDescription
      isSignedIn = false
    }
  }

  func signIn() async {
    do {
      errorMessage = nil
      try await auth.signInInteractive()
      isSignedIn = true
      await refresh()
    } catch {
      errorMessage = error.localizedDescription
      isSignedIn = false
    }
  }

  func signOut() {
    auth.signOut()
    isSignedIn = false
    report = nil
    errorMessage = nil
  }

  func refresh() async {
    do {
      errorMessage = nil
      isLoading = true
      defer { isLoading = false }

      let accessToken = try await auth.accessToken()
      let accounts = try await api.listAccounts(accessToken: accessToken)
      guard let account = accounts.first else {
        throw NSError(domain: "AdMob", code: 1, userInfo: [NSLocalizedDescriptionKey: "No AdMob accounts found for this Google user."])
      }

      let detailedReport = try await api.detailedReport(parentAccountName: account.name, dateRangeOption: selectedDateRange, accessToken: accessToken)
      report = detailedReport
    } catch {
      errorMessage = error.localizedDescription
      report = nil
    }
  }
}
