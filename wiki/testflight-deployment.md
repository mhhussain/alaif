---
title: TestFlight Deployment Guide
type: guide
created: 2026-06-09
---

# TestFlight Deployment Guide

Quick-reference for getting Alaif onto a device and into TestFlight. Written
for someone comfortable with Xcode/App Store Connect but new to the Flutter
release flow.

## 1. Bundle ID & app record

- Current bundle ID: `com.alaif.alaif` (set in
  `app/ios/Runner.xcodeproj/project.pbxproj`, `PRODUCT_BUNDLE_IDENTIFIER`).
  Decide now if you want to change it (e.g. to a domain-backed reverse-DNS
  you control) — it's painful to change after TestFlight builds exist, since
  the bundle ID is tied to the App Store Connect app record and any
  provisioning profiles.
- To change it: open `app/ios/Runner.xcworkspace` in Xcode → select the
  **Runner** target → **General** tab → **Bundle Identifier**. Update it for
  both the `Runner` and `RunnerTests` targets if needed (RunnerTests just
  needs to not collide).
- In **App Store Connect** (appstoreconnect.apple.com):
  - Apps → **+** → New App
  - Platform: iOS, Name: "Alaif" (or your chosen name), Primary language,
    Bundle ID: select the matching one (it must already exist in your
    Apple Developer account's Identifiers list — Xcode can auto-register it
    if "Automatically manage signing" is on, see below).
  - SKU: any internal string (e.g. `alaif-ios`).

## 2. Signing

- Open `app/ios/Runner.xcworkspace` (not the `.xcodeproj` — Flutter projects
  use CocoaPods workspaces).
- Runner target → **Signing & Capabilities**:
  - Check **Automatically manage signing**.
  - Select your **Team** (your Apple Developer account/org).
  - Xcode will create/refresh the provisioning profile and register the
    bundle ID automatically if it doesn't exist yet.
- Do this for the `Runner` target only — `RunnerTests` doesn't need to be
  archived/uploaded.

## 3. Version & build number

- Edit `app/pubspec.yaml`:
  ```yaml
  version: 1.0.0+1
  ```
  Format is `<version>+<build>` → CFBundleShortVersionString = `1.0.0`,
  CFBundleVersion = `1`.
- Each TestFlight upload **must have a unique build number** for a given
  version string. Bump the `+N` (e.g. `1.0.0+2`) for every new upload, or
  override at build time with `--build-number` (see below). The version
  string (`1.0.0`) can stay the same across builds during testing.

## 4. Build the IPA

From `app/`:

```bash
flutter clean   # optional, but recommended for first release build
flutter pub get
flutter build ipa --release
```

- Optional overrides without editing pubspec.yaml:
  ```bash
  flutter build ipa --release --build-name=1.0.0 --build-number=2
  ```
- Output location:
  ```
  app/build/ios/ipa/alaif.ipa
  ```
  (or whatever your app name resolves to — check `app/build/ios/ipa/` after
  the build).
- If this is your first iOS release build, expect CocoaPods to run
  (`pod install` happens automatically as part of `flutter build`). If you
  hit Pod errors, see Gotchas below.

## 5. Upload to App Store Connect

Three options — pick whichever fits your workflow:

1. **Xcode Organizer** (simplest if you already have Xcode open):
   - `flutter build ipa` also leaves an archive you can open, or just run
     `open app/build/ios/archive/Runner.xcarchive` (path may vary) in Xcode
     → Window → Organizer → Distribute App → App Store Connect → Upload.
2. **Transporter app** (Mac App Store, free):
   - Open Transporter → drag in `alaif.ipa` → Deliver. This is the modern
     replacement for `altool`/`iTMSTransporter` and is the easiest CLI-free
     path.
3. **Command line** (`xcrun altool` is deprecated; use `xcrun notarytool`'s
   sibling for App Store uploads — actually for App Store binaries the
   supported CLI path today is via **Transporter's CLI** or
   `xcrun altool --upload-app` still works for many but is being phased out).
   Practical recommendation: just use the **Transporter app** — it's
   actively maintained and avoids deprecated-tool churn:
   ```bash
   xcrun iTMSTransporter -m upload -assetFile app/build/ios/ipa/alaif.ipa \
     -u <apple-id> -p <app-specific-password>
   ```
   (Older Xcode toolchains only — if this binary doesn't exist on your
   system, use the Transporter app instead.)

After upload, the build appears in App Store Connect → your app → TestFlight
tab within a few minutes, after Apple finishes processing (you'll get an
email).

## 6. TestFlight testing

- **Internal testing** (up to 100 users, must be on your App Store Connect
  team / added as testers in Users and Access): available **immediately**
  after processing — no Beta App Review needed. Best for you and any
  collaborators initially.
- **External testing** (up to 10,000 testers via public/group links):
  requires a one-time **Beta App Review** (usually faster/lighter than full
  App Store review, but still a wait — budget 24-48h). Add a build to an
  external group to trigger it.
- For solo dev iteration, just add yourself as an internal tester and install
  via the TestFlight app on your device.

## 7. Run locally on a real device first

Before burning a TestFlight upload cycle, validate on-device:

```bash
flutter devices                       # confirm your iPhone is listed (trust the Mac on-device)
flutter run --release -d <device-id>  # release mode: closest to what TestFlight users get
```

- Use **`--release`** for a true performance/feel check (debug mode is much
  slower and not representative — relevant given the simulator swipe input
  felt laggy).
- Use **`--profile`** mode (`flutter run --profile -d <device-id>`) when you
  want to attach DevTools/profiling tools while still getting near-release
  performance — best option for diagnosing the swipe/slice responsiveness
  issue specifically.
- First run on a new physical device requires trusting your developer
  certificate on the device (Settings → General → VPN & Device Management).

## 8. Common Flutter iOS gotchas

- **CocoaPods**: Flutter's iOS build depends on CocoaPods. If `pod install`
  fails or pods are stale: `cd app/ios && pod install --repo-update`, or
  delete `app/ios/Pods` and `app/ios/Podfile.lock` and let `flutter build`
  regenerate them.
- **Minimum iOS version**: currently `IPHONEOS_DEPLOYMENT_TARGET = 13.0` in
  the Xcode project (Flutter's Xcode 13 default). If you want to drop support
  for very old devices or need a newer API, raise this in the Runner target's
  build settings *and* `app/ios/Podfile` (`platform :ios, '13.0'`) — keep
  them in sync.
- **Impeller**: Impeller is the default rendering backend on iOS for current
  Flutter versions (replaces Skia). It's generally faster, but if you see
  unexpected rendering glitches/shader-compile hitches, you can temporarily
  force the old Skia backend for comparison with
  `flutter run --no-enable-impeller` (or the equivalent build flag) — useful
  if odd visual artifacts show up only on iOS.
- **Xcode workspace vs project**: always open `Runner.xcworkspace`, never
  `Runner.xcodeproj`, once CocoaPods is in play — opening the wrong one
  leads to "missing module" build errors.
- **Build number collisions**: App Store Connect rejects re-uploads with a
  build number it's already seen for that version — bump
  `pubspec.yaml`'s `+N` (or pass `--build-number`) every upload.
- **Background color flash**: Flutter apps can show a white flash on launch
  before the first frame renders; if it's jarring against Alaif's dark
  `0xFF120C1D` background, set the `LaunchScreen` storyboard background to
  match (in `app/ios/Runner/Base.lproj/LaunchScreen.storyboard`).
