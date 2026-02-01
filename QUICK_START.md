# Quick Start - Play Store Deployment

## 🚀 Quick Deployment Steps

### 1. Setup Signing (First Time Only)

```bash
# Navigate to android directory
cd android

# Generate keystore
keytool -genkey -v -keystore keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias findmytutor

# Copy template and configure
cp key.properties.template key.properties
# Edit key.properties with your keystore details
```

### 2. Build Release AAB

```bash
# From project root
flutter clean
flutter pub get
flutter build appbundle --release
```

### 3. Upload to Play Console

1. Go to [Play Console](https://play.google.com/console)
2. Create new release
3. Upload `build/app/outputs/bundle/release/app-release.aab`
4. Add release notes
5. Submit for review

## 📋 Pre-Upload Checklist

- [ ] Version updated in `pubspec.yaml`
- [ ] Keystore configured
- [ ] Release build tested
- [ ] All features working
- [ ] Permissions documented
- [ ] Privacy policy URL added
- [ ] Data safety completed
- [ ] Screenshots ready
- [ ] Store listing complete

## 🔧 Common Commands

```bash
# Build release AAB
flutter build appbundle --release

# Build release APK (for testing)
flutter build apk --release

# Install release APK
flutter install --release

# Check app version
flutter --version

# Clean build
flutter clean
```

## 📱 App Information

- **Package Name**: `com.findmytutor.app`
- **Min SDK**: 23 (Android 6.0+)
- **Target SDK**: Latest
- **Version**: 1.0.1+3

## 🔐 Security Notes

- Never commit `key.properties` or `keystore.jks`
- Store keystore password securely
- Use different keystores for dev/staging/production
- Backup keystore file securely

## 📞 Support

For detailed instructions, see:
- `DEPLOYMENT_GUIDE.md` - Full deployment guide
- `PLAY_STORE_CHECKLIST.md` - Complete checklist

## ⚠️ Important

- Always test release builds before uploading
- Use staged rollouts (start with 20%)
- Monitor crash reports after release
- Keep dependencies updated

