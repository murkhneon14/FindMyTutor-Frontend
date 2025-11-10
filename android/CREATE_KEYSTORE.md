# Creating Keystore for Play Store

## Quick Setup (Windows)

### Option 1: If Java is installed but not in PATH

1. Find your Java installation (usually in `C:\Program Files\Java\jdk-XX` or `C:\Program Files\Eclipse Adoptium\jdk-XX`)
2. Open Command Prompt or PowerShell in the `android` folder
3. Run (replace path with your Java path):
   ```
   "C:\Program Files\Java\jdk-XX\bin\keytool.exe" -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass findmytutor2024 -keypass findmytutor2024 -dname "CN=FindMyTutor, OU=Development, O=FindMyTutor, L=City, ST=State, C=IN"
   ```

### Option 2: Install Java JDK

1. Download Java JDK from: https://adoptium.net/
2. Install it
3. Add Java to PATH or use full path to keytool
4. Run the command above

### Option 3: Use Android Studio's JDK

If you have Android Studio installed:
1. Find JDK path (usually in Android Studio installation)
2. Use that keytool.exe path

## After Creating Keystore

The `key.properties` file is already created with:
- storePassword: findmytutor2024
- keyPassword: findmytutor2024
- keyAlias: upload
- storeFile: upload-keystore.jks

**IMPORTANT:** Keep the keystore file safe! You'll need it for all future updates to Play Store.

## Build AAB

Once keystore is created, run:
```bash
cd frontend/FindMyTutor-Frontend
flutter build appbundle --release
```

The AAB file will be at: `build/app/outputs/bundle/release/app-release.aab`


