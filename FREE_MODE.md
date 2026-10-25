# PocketFlash Free Mode

This reconstructed source project is configured for owner-authorized Free Mode. The features implemented in this project (local SWF library, importing/removing SWF files, and the Ruffle playback attempt) are not guarded by an in-app purchase or paywall.

Configuration in `lib/main.dart`:
- `AppEntitlements.freeModeEnabled = true`
- `AppEntitlements.premiumGateEnabled = false`

This is not a patch to the original IPA and does not unlock paid features in a third-party app. The original Dart source was not present in the IPA, so this setting only applies to the reconstructed project.
