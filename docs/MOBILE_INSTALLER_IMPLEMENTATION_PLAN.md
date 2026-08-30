# 📱 Implementation Plan: Mobile Cross-Platform Packaging & Installer Pipeline

This plan outlines the architecture, directory structure, keystore/certificate configurations, and build/packaging scripts required to create release packages for the **Mobile Cross-Platform Application** (`apps/mobile`), including **Android APKs/AAB App Bundles** and **iOS IPA Archives**.

---

## 📐 Architecture & Reference Mapping

Modeled directly after the **Remote Access Platform** desktop packaging architecture (`docs/INSTALLER_IMPLEMENTATION_PLAN.md` & `build-scripts/`), adapted for Flutter mobile cross-platform distribution:

```
remote-access-platform/
├── VERSION                                       # Centralized version source of truth (0.3.0)
├── .env.example                                  # Added ANDROID_SDK_ROOT, FLUTTER_ROOT, KEYSTORE overrides
├── docs/
│   └── MOBILE_INSTALLER_IMPLEMENTATION_PLAN.md   # Persistent architecture & execution document
├── build-scripts/
│   ├── package-android.sh                        # Bash script for Linux/macOS to build release APKs & AAB
│   ├── package-android.ps1                       # PowerShell script for Windows hosts to build APKs & AAB
│   └── package-ios.sh                            # Bash script for macOS to archive & export signed iOS IPA
└── apps/mobile/
    ├── android/
    │   └── key.properties.example                # Keystore signing configuration template
    └── ios/
        └── ExportOptions.plist.example           # iOS IPA export options template (Ad-Hoc / App Store)
```

---

## 🛠️ Proposed Changes

### 1. Versioning & Signing Configuration

#### [MODIFY] [pubspec.yaml](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/apps/mobile/pubspec.yaml)
- Synchronize version identifier with central `VERSION` file: `version: 0.3.0+1`.

#### [NEW] [key.properties.example](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/apps/mobile/android/key.properties.example)
- Keystore credentials reference for Android production signing (`storePassword`, `keyPassword`, `keyAlias`, `storeFile`).

#### [MODIFY] [build.gradle.kts](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/apps/mobile/android/app/build.gradle.kts)
- Configure `signingConfigs` block reading `key.properties` when available, falling back to debug signing for local testing.

#### [NEW] [ExportOptions.plist.example](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/apps/mobile/ios/ExportOptions.plist.example)
- iOS distribution profile configuration for `xcodebuild -exportArchive` (Ad-Hoc, Enterprise, or App Store).

---

### 2. Automated Build & Packaging Scripts (`build-scripts/`)

#### [NEW] [package-android.sh](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/build-scripts/package-android.sh)
- **Purpose**: Linux/macOS automated Android build runner.
- **Features**:
  - Reads `VERSION` file for `APP_VERSION`.
  - Auto-locates Flutter SDK and Android SDK (`ANDROID_HOME` / `ANDROID_SDK_ROOT`).
  - Stages JNI native C-ABI libraries (`librap_common.so` / `librap_client_ffi.so`) into `android/app/src/main/jniLibs/{arm64-v8a,armeabi-v7a,x86_64}`.
  - Compiles:
    1. **Universal Release APK**: `build/app/outputs/flutter-apk/app-release.apk`
    2. **Per-ABI Split APKs**: `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk`, `app-x86_64-release.apk`
    3. **Play Store App Bundle**: `build/app/outputs/bundle/release/app-release.aab`
  - Generates SHA-256 checksums and moves artifacts into `dist/mobile/android/`.

#### [NEW] [package-android.ps1](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/build-scripts/package-android.ps1)
- **Purpose**: Windows PowerShell automated Android build runner.
- **Features**:
  - Reads `.env` for `FLUTTER_ROOT`, `ANDROID_SDK_ROOT`, and `KEYSTORE_PATH`.
  - Bundles native C++ FFI DLLs / JNI libraries into Flutter project.
  - Runs `flutter build apk --release` and `flutter build appbundle --release`.
  - Generates SHA-256 checksums and outputs to `dist\mobile\android\`.

#### [NEW] [package-ios.sh](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/build-scripts/package-ios.sh)
- **Purpose**: macOS automated iOS IPA build runner.
- **Features**:
  - Validates macOS environment, Xcode command line tools, and CocoaPods (`pod install`).
  - Links native C-ABI framework / static library (`librap_common.a` / `librap_client_ffi.a`).
  - Runs `flutter build ipa --release --export-options-plist=apps/mobile/ios/ExportOptions.plist`.
  - Outputs signed `RemoteAccessPlatform-0.3.0.ipa` into `dist/mobile/ios/`.

---

### 3. Persistent Documentation

#### [NEW] [MOBILE_INSTALLER_IMPLEMENTATION_PLAN.md](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/docs/MOBILE_INSTALLER_IMPLEMENTATION_PLAN.md)
- Persistent architecture plan saved inside `docs/` repository directory following repository governance rules.

---

## 🎯 Target Output Artifacts

| Platform | Output File | Destination | Description |
|---|---|---|---|
| **Android** | `RemoteAccessPlatform-0.3.0.apk` | `dist/mobile/android/` | Standalone universal APK for direct sideloading |
| **Android** | `RemoteAccessPlatform-0.3.0-arm64-v8a.apk` | `dist/mobile/android/` | Optimized APK for modern 64-bit ARM devices |
| **Android** | `RemoteAccessPlatform-0.3.0.aab` | `dist/mobile/android/` | Android App Bundle for Google Play Store upload |
| **iOS** | `RemoteAccessPlatform-0.3.0.ipa` | `dist/mobile/ios/` | Signed iOS application package for TestFlight / Ad-Hoc |
| **Checksums** | `checksums.txt` | `dist/mobile/` | SHA-256 & MD5 hashes for all mobile release packages |

---

## 🧪 Verification Plan

### Manual Verification (User-Driven)
1. **Android APK Build Verification**:
   - Run `bash build-scripts/package-android.sh` (or `powershell -ExecutionPolicy Bypass -File build-scripts/package-android.ps1`).
   - Confirm `dist/mobile/android/RemoteAccessPlatform-0.3.0.apk` is generated with valid JNI native library dependencies.
2. **Android App Bundle Verification**:
   - Verify `dist/mobile/android/RemoteAccessPlatform-0.3.0.aab` is generated.
3. **iOS Archive Verification (macOS)**:
   - Run `bash build-scripts/package-ios.sh`.
   - Confirm `dist/mobile/ios/RemoteAccessPlatform-0.3.0.ipa` is built cleanly.
