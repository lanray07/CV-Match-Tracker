# GitHub Xcode Build

This repository can use GitHub-hosted macOS runners to build CV Match Tracker with Xcode.

## Simulator Build

The `iOS Simulator Build` workflow runs automatically on pushes to `main` and can also be started manually from GitHub Actions.

It builds the app with:

- `CVMatchTracker.xcodeproj`
- scheme `CVMatchTracker`
- iOS Simulator SDK
- code signing disabled

This is useful when you do not have a Mac and want GitHub to prove the app compiles with Xcode.

## App Store Upload

The `iOS App Store Archive Upload` workflow is manual because it uploads a signed `.ipa` to App Store Connect.

Add these GitHub repository secrets before running it:

- `APPLE_TEAM_ID`
- `IOS_DISTRIBUTION_CERTIFICATE_BASE64`
- `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_PRIVATE_KEY`

The certificate must be an Apple Distribution `.p12` certificate encoded as base64.
The provisioning profile must be an App Store provisioning profile for `com.lanray07.cvmatchtracker`, encoded as base64.
The App Store Connect private key should be the full `.p8` key contents.

After the upload workflow succeeds, App Store Connect will process the build. Once processing finishes, select that build on the iOS App Version page and then submit for review.
