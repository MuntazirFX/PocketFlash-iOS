# Build PocketFlash on GitHub Actions

This reconstructed ZIP did not include an Xcode `ios/` directory, so `.github/workflows/build-ios.yml` creates the missing iOS platform project on the GitHub macOS runner before building.

## Add the project to GitHub

1. Create/open your GitHub repository.
2. Upload and commit the contents of this ZIP to the repository root (make sure `.github/workflows/build-ios.yml` is included).
3. Open **Actions → Build PocketFlash iOS → Run workflow**. A push to `main` or `master` also starts a build.

## Build output

- **Without signing secrets:** the workflow creates an unsigned `.xcarchive`. This is a build artifact for a later signing step; it is not an installable IPA.
- **With signing secrets:** the workflow attempts to export an Ad Hoc-signed IPA and uploads `PocketFlash-IPA`.

## Required GitHub Actions secrets for an installable IPA

In **Repository → Settings → Secrets and variables → Actions**, add:

- `APPLE_TEAM_ID`: your Apple Developer Team ID.
- `IOS_CERTIFICATE_BASE64`: base64-encoded Apple Distribution `.p12` certificate.
- `IOS_CERTIFICATE_PASSWORD`: password for that `.p12` file.
- `IOS_PROVISIONING_PROFILE_BASE64`: base64-encoded Ad Hoc provisioning profile for `com.jimmystudio.pocketflash`.
- `IOS_PROFILE_NAME`: optional informational secret; the workflow reads the profile name from the profile file, so this secret is not required.

The certificate and profile must belong to an Apple Developer team and match the bundle ID `com.jimmystudio.pocketflash`. The profile must allow Ad Hoc distribution and include the target iPhone UDIDs. Keep signing files and passwords private; never commit them into the repository.

## Important

The workflow builds the reconstructed Flutter project in this repository; it does not patch the old compiled `Runner.ipa`. The reconstructed app is a best-effort starter and still needs a successful GitHub build and device testing. The unsigned fallback cannot be installed directly on an iPhone.
