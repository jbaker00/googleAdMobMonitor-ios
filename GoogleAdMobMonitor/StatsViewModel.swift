import Foundation

@MainActor
final class StatsViewModel: ObservableObject {
  @Published private(set) var isSignedIn = false
  @Published private(set) var isLoading = false
  @Published private(set) var report: DetailedReport?
  @Published private(set) var multiPeriodReport: MultiPeriodReport?
  @Published var errorMessage: String?
  @Published var selectedDateRange: DateRangeOption = .monthToDate
  @Published var payoutHistory: [PayoutEntry] = []
  @Published var payoutTotalMicros: Int64? = nil
  @Published var payoutCurrency: String = ""

  // Load detailed payouts on demand (for all-time view). Tracks whether details have been loaded.
  private(set) var payoutDetailsLoaded = false

  // Public convenience: load payout details using stored auth/account info
  func loadPayoutDetails() async {
    guard !payoutDetailsLoaded else { return }
    do {
      let accessToken = try await auth.accessToken()
      let accounts = try await api.listAccounts(accessToken: accessToken)
      guard let account = accounts.first else { return }
      payoutHistory = try await api.payoutHistory(parentAccountName: account.name, months: 0, accessToken: accessToken)
      payoutDetailsLoaded = true
    } catch {
      payoutHistory = []
      payoutDetailsLoaded = false
    }
  }

  // Internal version if caller already has account/accessToken
  func loadPayoutDetailsIfNeeded(parentAccountName: String, accessToken: String) async {
    guard !payoutDetailsLoaded else { return }
    do {
      payoutHistory = try await api.payoutHistory(parentAccountName: parentAccountName, months: 0, accessToken: accessToken)
      payoutDetailsLoaded = true
    } catch {
      payoutHistory = []
      payoutDetailsLoaded = false
    }
  }

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

      // Fetch both the standard report and the multi-period report
      async let detailedReportTask = api.detailedReport(parentAccountName: account.name, dateRangeOption: selectedDateRange, accessToken: accessToken)
      async let multiPeriodReportTask = api.multiPeriodReport(parentAccountName: account.name, accessToken: accessToken)
      
      let (fetchedDetailedReport, fetchedMultiPeriodReport) = try await (detailedReportTask, multiPeriodReportTask)
      
      report = fetchedDetailedReport
      multiPeriodReport = fetchedMultiPeriodReport

      // Load only the payout total for the selected date range. Detailed history is loaded on demand.
      do {
        let (micros, currency) = try await api.payoutTotal(parentAccountName: account.name, dateRangeOption: selectedDateRange, accessToken: accessToken)
        payoutTotalMicros = micros
        payoutCurrency = currency
      } catch {
        payoutTotalMicros = nil
        payoutCurrency = ""
      }
    } catch {
      errorMessage = error.localizedDescription
      report = nil
      multiPeriodReport = nil
    }
  }
}
