## Play Store Release Checklist

### 1) Prepare signing key (one-time)
- Copy `android/key.properties.example` to `android/key.properties`.
- Create upload keystore if needed:
  - `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
- Put the `.jks` file inside `android/` (or update `storeFile` path in `key.properties`).

### 2) Bump app version before each upload
- Update `version` in `pubspec.yaml`:
  - Format: `x.y.z+buildNumber`
  - `buildNumber` must be greater than previous Play upload.

### 3) Build production AAB
- `flutter clean`
- `flutter pub get`
- `flutter build appbundle --release`

Output:
- `build/app/outputs/bundle/release/app-release.aab`

### 4) Upload in Play Console
- Create/update app release.
- Upload the generated `.aab`.
- Fill release notes.
- Review Data Safety + permissions declarations (location, notifications, camera/media, ad ID if used).

### 5) Final pre-submit checks
- Test release build on physical device.
- Verify login/signup, notifications, payments, location search, and chat.
- Confirm privacy policy URL and support email are valid in store listing.
