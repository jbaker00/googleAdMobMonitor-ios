# GoogleAdMobMonitor (iOS)

SwiftUI app scaffold that signs into Google and calls the **AdMob Reporting API** to display **month-to-date** network stats.

## Prerequisites
- Xcode (to build/run on iOS Simulator or device)
- An AdMob account with reporting access
- A Google Cloud project with the **AdMob API** enabled

## Google Cloud / OAuth setup (required)
1. In Google Cloud Console:
   - Enable **AdMob API** for your project.
   - Configure the OAuth consent screen.
2. Create OAuth client credentials:
   - Create an **OAuth Client ID** of type **iOS**.
   - Set bundle id to: `com.jamesbaker.googleAdMobMonitor`
3. In Xcode, add **Google Sign-In** via Swift Package Manager:
   - Package URL: `https://github.com/google/GoogleSignIn-iOS`
4. Configure URL scheme (required by Google Sign-In):
   - From your OAuth client, take the `REVERSED_CLIENT_ID` value.
   - In Xcode: Target → Info → URL Types → add the reversed client id as a URL scheme.

## Runtime configuration
In `AdMobAuthManager.swift`, set your OAuth client id:
- Replace `YOUR_IOS_OAUTH_CLIENT_ID.apps.googleusercontent.com` with your iOS client id.

The app requests the scope:
- `https://www.googleapis.com/auth/admob.readonly`

## What the app does
- Sign in with Google.
- Calls `GET https://admob.googleapis.com/v1/accounts` to find your publisher account.
- Calls `POST https://admob.googleapis.com/v1/accounts/*/networkReport:generate` for month-to-date totals.

## Notes
- Do **not** commit OAuth client secrets; this app only needs the **client id** (public).
- Earnings returned by the API are in **micros**; the UI converts to standard currency units.
