# Building AAB for Play Store

## Prerequisites

1. **Java JDK** - Required for creating keystore
   - Download from: https://adoptium.net/
   - Or use Android Studio's JDK (if installed)

## Step 1: Create Keystore

### Option A: Using PowerShell Script (Recommended)

1. Open PowerShell in the `android` folder
2. Run:
   ```powershell
   .\create-keystore-manual.ps1
   ```

### Option B: Manual Creation

1. Find Java keytool (usually in `C:\Program Files\Java\jdk-XX\bin\keytool.exe`)
2. Open Command Prompt in the `android` folder
3. Run:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass findmytutor2024 -keypass findmytutor2024 -dname "CN=FindMyTutor, OU=Development, O=FindMyTutor, L=City, ST=State, C=IN"
   ```

### Option C: Using Android Studio's JDK

If you have Android Studio installed:
```bash
"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass findmytutor2024 -keypass findmytutor2024 -dname "CN=FindMyTutor, OU=Development, O=FindMyTutor, L=City, ST=State, C=IN"
```

**IMPORTANT:** Keep the `upload-keystore.jks` file safe! You'll need it for all future Play Store updates.

## Step 2: Verify Keystore Created

The keystore file should be at: `android/upload-keystore.jks`

The `key.properties` file is already configured with:
- storePassword: findmytutor2024
- keyPassword: findmytutor2024
- keyAlias: upload
- storeFile: upload-keystore.jks

## Step 3: Build AAB

Once keystore is created, run:

```bash
cd frontend/FindMyTutor-Frontend
flutter build appbundle --release
```

## Step 4: Find Your AAB File

The AAB file will be at:
```
frontend/FindMyTutor-Frontend/build/app/outputs/bundle/release/app-release.aab
```

## Upload to Play Store

1. Go to Google Play Console: https://play.google.com/console
2. Create a new app or select existing app
3. Go to "Production" → "Create new release"
4. Upload the `app-release.aab` file
5. Fill in release notes and submit

## Troubleshooting

### Error: Keystore file not found
- Make sure `upload-keystore.jks` is in the `android` folder
- Check that `key.properties` file exists in `android` folder

### Error: Java not found
- Install Java JDK from https://adoptium.net/
- Or add Java to your PATH environment variable

### Error: NDK version mismatch
- Already fixed! NDK version is set to 27.0.12077973


