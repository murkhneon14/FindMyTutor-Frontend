# Quick Build Instructions

## To Build AAB for Play Store:

### 1. Create Keystore (One-time setup)

**If you have Java installed:**
```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass findmytutor2024 -keypass findmytutor2024 -dname "CN=FindMyTutor, OU=Development, O=FindMyTutor, L=City, ST=State, C=IN"
```

**If you have Android Studio:**
```bash
cd android
"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass findmytutor2024 -keypass findmytutor2024 -dname "CN=FindMyTutor, OU=Development, O=FindMyTutor, L=City, ST=State, C=IN"
```

### 2. Build AAB

```bash
flutter build appbundle --release
```

### 3. Find Your AAB

Location: `build/app/outputs/bundle/release/app-release.aab`

**That's it!** Upload this file to Google Play Console.


