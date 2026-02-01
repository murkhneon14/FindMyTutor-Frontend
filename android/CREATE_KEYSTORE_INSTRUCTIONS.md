# Create Keystore for Play Store

## Quick Method (Recommended)

### Option 1: Using the Batch Script (Windows)

1. Open Command Prompt or PowerShell in the `android` folder
2. Run:
   ```batch
   create-keystore-now.bat
   ```

### Option 2: Manual Creation

1. Open Command Prompt or PowerShell in the `android` folder
2. Run this command:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass findmytutor2024 -keypass findmytutor2024 -dname "CN=FindMyTutor, OU=Development, O=FindMyTutor, L=City, ST=State, C=IN"
   ```

### Option 3: If Java is not in PATH

If you get "keytool is not recognized", find your Java installation:

**For Android Studio users:**
- Java is usually at: `C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`
- Or: `%LOCALAPPDATA%\Android\Sdk\jdk\bin\keytool.exe`

**For Java JDK users:**
- Java is usually at: `C:\Program Files\Java\jdk-XX\bin\keytool.exe`
- Or: `C:\Program Files\Eclipse Adoptium\jdk-XX\bin\keytool.exe`

Then run:
```bash
"FULL_PATH_TO_KEYTOOL.exe" -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass findmytutor2024 -keypass findmytutor2024 -dname "CN=FindMyTutor, OU=Development, O=FindMyTutor, L=City, ST=State, C=IN"
```

## Verify Keystore Creation

After running the command, you should see:
- File created: `upload-keystore.jks` in the `android` folder
- Success message

## Build Release AAB

Once keystore is created, build the AAB:

```bash
cd frontend/FindMyTutor-Frontend
flutter clean
flutter pub get
flutter build appbundle --release
```

## Important Notes

1. **Keep the keystore safe!** You'll need it for all future updates
2. **Backup the keystore** to a secure location
3. **Remember the passwords**: storePassword and keyPassword are both `findmytutor2024`
4. **Key alias**: `upload`

## Troubleshooting

### Error: "keytool is not recognized"
- Install Java JDK or use Android Studio's JDK
- Add Java to PATH, or use full path to keytool.exe

### Error: "Keystore file not found" during build
- Make sure `upload-keystore.jks` is in the `android` folder
- Verify `key.properties` has correct path: `storeFile=upload-keystore.jks`

### Error: "Password was incorrect"
- Check `key.properties` matches keystore passwords
- Default passwords are: `findmytutor2024`

## Current Configuration

- **Keystore file**: `upload-keystore.jks`
- **Key alias**: `upload`
- **Store password**: `findmytutor2024`
- **Key password**: `findmytutor2024`
- **Validity**: 10000 days (~27 years)

## Next Steps

1. Create keystore (using instructions above)
2. Build AAB: `flutter build appbundle --release`
3. Upload to Play Console
4. Complete store listing
5. Submit for review

