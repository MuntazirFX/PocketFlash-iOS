# PocketFlash reconstructed starter

This is a **new starter project reconstructed from bundled files in `Runner.ipa`**, not the original source tree. The IPA contained Flutter compiled output and assets, but not the original Dart source. The project is a best-effort baseline and has not been compiled or tested in Xcode in this environment.

## Included
- Bundled Ruffle JavaScript/WebAssembly and the original `player.html`/sample SWF assets extracted from the IPA.
- Offline library with `.swf` file import, persistent local file storage, remove action, and playback attempt through Ruffle.
- **Owner-authorized Free Mode:** this reconstructed build has no paywall or purchase gate for its included features. `AppEntitlements.freeModeEnabled` is `true` and `premiumGateEnabled` is `false` in `lib/main.dart`.
- No in-app-purchase plugin dependency in this reconstructed starter.

## Build
- **GitHub Actions:** see [`GITHUB_BUILD.md`](GITHUB_BUILD.md). The workflow creates the missing `ios/` platform project, then builds on a macOS runner.
- **Local Mac:** install Flutter SDK and Xcode, run `flutter create --platforms=ios --org com.jimmystudio --project-name pocketflash .`, then `flutter pub get`. For a device-installable IPA, configure Apple signing and run `flutter build ipa --release`.

## Important limits
- The source is reconstructed, not byte-for-byte original. There may be API/version adjustments required after `flutter pub get` and a real iOS build.
- Ruffle does not support every Flash title; game compatibility depends on the SWF's Flash version/APIs.
- Local SWF loading passes bytes to Ruffle via a JavaScript bridge. Very large SWFs can use substantial memory; test on a real device.
- The old IPA itself has not been patched or re-signed. Free Mode applies only to this newly reconstructed project; it does not modify or bypass purchase checks in the original IPA or any third-party app.
- Original app signing credentials, App Store Connect credentials, and original Dart source cannot be recovered from the IPA.
