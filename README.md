# GoogleAdMobMonitor (iOS)

SwiftUI app scaffold that signs into Google and calls the **AdMob Reporting API** to display publisher statistics and per-app breakdowns.

## Repository layout
- GoogleAdMobMonitor/ — Swift source files (App, ViewModel, Auth, API client, UI)
- GoogleAdMobMonitor.xcodeproj — generated Xcode project (via xcodegen)
- project.yml — xcodegen spec
- .github/copilot-instructions.md — helper for AI assistants

## Prerequisites
- Xcode (recommended latest stable)
- xcodegen (optional; used to regenerate the Xcode project from project.yml)
- `gh` (GitHub CLI) if you plan to create/push repos from the command line
- An AdMob publisher account with reporting access
- A Google Cloud project with the **AdMob API** enabled

## Google Cloud / OAuth setup (required)
1. In Google Cloud Console:
   - Enable **AdMob API** for your project.
   - Configure the OAuth consent screen (external or internal depending on your needs).
2. Create OAuth client credentials:
   - Click **Create Credentials → OAuth Client ID**
   - Application type: **iOS**
   - Name: `AdMob Stats iOS`
   - Bundle ID: `com.jamesbaker.googleAdMobMonitor`
   - Copy the **Client ID** (ends with `.apps.googleusercontent.com`).
3. In the app, configure the reversed client id as a URL scheme (Google Sign-In callback):
   - If using xcodegen, update `project.yml` info.url schemes; otherwise open Target → Info → URL Types and add the reversed client id.

Note: Do NOT use a 'Web application' OAuth client for iOS sign-in. Web clients disallow custom scheme URIs.

## Local setup and run
1. Clone the repo (or pull if already present):
   git clone https://github.com/jbaker00/googleAdMobMonitor-ios.git
2. If you make edits to Swift sources, either open the existing `GoogleAdMobMonitor.xcodeproj` in Xcode, or regenerate it with xcodegen:
   cd googleAdMobMonitor-ios
   xcodegen generate
3. Open `GoogleAdMobMonitor.xcodeproj` in Xcode.
4. In `GoogleAdMobMonitor/AdMobAuthManager.swift` set:
   private let clientID = "<YOUR_IOS_CLIENT_ID>.apps.googleusercontent.com"
5. Build and run on a simulator or device (select a target, then ⌘R).
6. On first run, tap **Sign in with Google** and complete the OAuth flow with the Google account that has AdMob access.

## Usage
- The home screen shows a segmented control to select time range: Month to Date (default), Last 30, Last 60, Last 1 Year, All Time.
- The summary shows totals and a per-app breakdown (sorted by earnings).
- Use the Refresh button to re-query the AdMob API for the selected range.

## Security & secrets
- iOS apps do not use a client secret; only the client ID and reversed scheme are required for Google Sign-In.
- Do not commit any sensitive credentials (OAuth client secrets, service account keys, etc.) to this repository.

## Developing further
- To add more metrics (e.g., IMPRESSION_RPM or CTR), update `AdMobAPIClient`'s `metrics` list and the UI fields.
- To show per-date rows rather than aggregated app totals, add the `DATE` dimension and adapt parsing/UI.

## Troubleshooting
- If you see errors about custom URI schemes not allowed, ensure you're using an **iOS OAuth client** in GCP (not Web application) and that the bundle id matches.
- If Google Sign-In fails with threading warnings, ensure `AdMobAuthManager`'s UI calls run on the main thread (they are annotated with @MainActor).

---

If you'd like, I can open a PR adding this README change and a short CONTRIBUTING.md; confirm and I will push the update.