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
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_PRIVATE_KEY`

The workflow uses Xcode automatic signing on GitHub's macOS runner. It archives without development signing, then lets Xcode sign the exported App Store IPA with the App Store Connect API key. The App Store Connect private key should be the full `.p8` key contents, including the `BEGIN PRIVATE KEY` and `END PRIVATE KEY` lines.

If the upload fails during signing, confirm the App Store Connect API key has enough access to manage signing for the Apple Developer team and that `APPLE_TEAM_ID` matches the team that owns `com.lanray07.cvmatchtracker`.

After the upload workflow succeeds, App Store Connect will process the build. Once processing finishes, select that build on the iOS App Version page and then submit for review.
