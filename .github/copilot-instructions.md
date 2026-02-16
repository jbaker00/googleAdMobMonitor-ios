# Copilot instructions (googleAdMobMonitor)

## Project overview
This repo currently contains an **iOS SwiftUI app scaffold** (source-only) that signs into Google and calls the **AdMob Reporting API** to show **month-to-date** stats.

Source files live under:
- `ios/GoogleAdMobMonitor/`

Setup notes live in:
- `ios/README.md`

## Build / run / test
There is **no committed Xcode project** (`.xcodeproj`) in this repo yet.

To run it locally:
1. Create a new **iOS App (SwiftUI)** project in Xcode.
2. Set bundle id to `com.jamesbaker.googleAdMobMonitor`.
3. Add the Swift files from `ios/GoogleAdMobMonitor/` to the target.
4. Add `GoogleSignIn` via Swift Package Manager (`https://github.com/google/GoogleSignIn-iOS`).
5. Add the OAuth URL scheme (`REVERSED_CLIENT_ID`) and set the client id constant in `AdMobAuthManager`.

No automated test suite or lint tooling is present in the repo.

## High-level architecture
- **UI**: `ContentView` renders either sign-in UI or stats UI.
- **State / orchestration**: `StatsViewModel` owns app state and coordinates auth + API calls.
- **Auth**: `AdMobAuthManager` uses `GoogleSignIn` to obtain an OAuth access token with scope `https://www.googleapis.com/auth/admob.readonly`.
- **AdMob API**: `AdMobAPIClient`
  - `listAccounts()` calls `GET /v1/accounts` and picks the first account.
  - `monthToDateSummary()` calls `POST /v1/{parent=accounts/*}/networkReport:generate` with no dimensions to request a single aggregated row.

Data flow: `ContentView` → `StatsViewModel.refresh()` → `AdMobAuthManager.accessToken()` → `AdMobAPIClient` → `MTDReportSummary` → UI.

## Key conventions / patterns
- Prefer **async/await** (no callbacks) for auth and network calls.
- Keep AdMob report metric names aligned with the API enums:
  - `ESTIMATED_EARNINGS` (micros), `IMPRESSIONS`, `CLICKS`, `AD_REQUESTS`.
- Don’t hardcode or commit secrets; only the **OAuth client id** is configured in code (public), and access tokens are obtained at runtime.
