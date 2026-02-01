# Deployment Guide - FindMyTutor

## Prerequisites

1. Flutter SDK installed (3.8.0 or higher)
2. Android Studio with Android SDK
3. Java JDK 11 or higher
4. Google Play Console account
5. Firebase project set up
6. Razorpay account (for payments)

## Step 1: App Signing Setup

### Generate Keystore (First Time Only)

```bash
cd android
keytool -genkey -v -keystore keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias findmytutor
```

**Important**: Save the keystore password and key password securely. You'll need them for future updates.

### Configure Signing

1. Copy the template:
   ```bash
   cp key.properties.template key.properties
   ```

2. Edit `key.properties` and fill in your values:
   ```
   storePassword=your_keystore_password
   keyPassword=your_key_password
   keyAlias=findmytutor
   storeFile=../keystore.jks
   ```

3. Verify `key.properties` and `keystore.jks` are in `.gitignore`

## Step 2: Update Version

Before each release, update the version in `pubspec.yaml`:

```yaml
version: 1.0.1+3  # Format: MAJOR.MINOR.PATCH+BUILD_NUMBER
```

- Increment BUILD_NUMBER (+3) for each release
- Increment PATCH for bug fixes
- Increment MINOR for new features
- Increment MAJOR for breaking changes

## Step 3: Build Release AAB

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release AAB (Android App Bundle)
flutter build appbundle --release
```

The AAB file will be located at:
```
build/app/outputs/bundle/release/app-release.aab
```

## Step 4: Test Release Build

Before uploading to Play Store, test the release build:

```bash
# Build release APK for testing
flutter build apk --release

# Install on device
flutter install --release
```

Test all features:
- [ ] User registration/login
- [ ] Profile creation
- [ ] Tutor/student search
- [ ] Location services
- [ ] Chat functionality
- [ ] Payment flow (Razorpay)
- [ ] Subscription purchase
- [ ] Notifications

## Step 5: Prepare Play Store Assets

### Required Assets

1. **App Icon**: 512 x 512 pixels (PNG, 32-bit)
2. **Feature Graphic**: 1024 x 500 pixels (JPG or 24-bit PNG)
3. **Screenshots**: 
   - Phone: At least 2, up to 8 (16:9 or 9:16)
   - Tablet (optional): At least 2, up to 8
4. **Short Description**: 80 characters max
5. **Full Description**: 4000 characters max

### Store Listing Information

**App Name**: FindMyTutor

**Short Description** (80 chars):
```
Connect with expert tutors nearby. Book sessions, learn anywhere, anytime.
```

**Full Description** (4000 chars):
```
FindMyTutor is a premium marketplace connecting students with qualified tutors. 

Key Features:
• Find tutors near you using location-based search
• Filter by subjects, grades, and preferences
• Secure in-app messaging
• Easy booking and session management
• Premium subscription for unlimited access
• Safe and secure payment processing

Whether you're a student looking for help or a teacher offering tutoring services, FindMyTutor makes it easy to connect and learn.

Download now and start your learning journey!
```

## Step 6: Upload to Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app (or create new app)
3. Go to **Production** → **Create new release**
4. Upload the AAB file
5. Add release notes
6. Review and roll out

### Staged Rollout (Recommended)

1. Start with **Internal Testing** track
2. Test with internal testers
3. Move to **Closed Testing** (alpha/beta)
4. Gradually roll out to **Production** (start with 20%)

## Step 7: Complete Store Listing

### App Details
- [ ] App name
- [ ] Short description
- [ ] Full description
- [ ] App icon
- [ ] Feature graphic
- [ ] Screenshots
- [ ] Category: Education
- [ ] Content rating
- [ ] Target audience

### Privacy & Security
- [ ] Privacy Policy URL
- [ ] Data Safety section completed
- [ ] Data collection practices disclosed
- [ ] Data sharing practices disclosed

### Permissions
Add permission descriptions in Play Console:

**Location (Approximate)**:
"We use your location to show you tutors and students near you. This helps you find the best matches in your area."

**Notifications**:
"We send notifications about new messages, booking updates, and important account information."

**Camera/Storage**:
"We access your camera and photos to let you upload profile pictures."

## Step 8: Content Rating

Complete the content rating questionnaire:
1. Go to **Policy** → **App content**
2. Answer all questions
3. Submit for rating

## Step 9: Data Safety

Complete the Data Safety section:
1. Go to **Policy** → **Data safety**
2. Answer questions about:
   - Data collection
   - Data sharing
   - Data security
   - Data deletion

## Step 10: Release

1. Review all information
2. Submit for review
3. Wait for approval (usually 1-3 days)
4. Monitor crash reports and user reviews
5. Respond to user feedback

## Troubleshooting

### Build Errors

**Error**: "Keystore file not found"
- Verify `key.properties` exists in `android/` directory
- Check `storeFile` path in `key.properties`

**Error**: "Signing config not found"
- Verify `key.properties` is configured correctly
- Check keystore file exists

### Upload Errors

**Error**: "Version code already used"
- Increment version code in `pubspec.yaml`
- Rebuild AAB

**Error**: "App bundle validation failed"
- Verify AAB is built with `--release` flag
- Check ProGuard rules
- Verify all dependencies are compatible

## Maintenance

### Regular Updates

1. Monitor crash reports in Play Console
2. Respond to user reviews
3. Fix bugs and release updates
4. Add new features
5. Keep dependencies updated

### Version Updates

For each update:
1. Update version in `pubspec.yaml`
2. Update release notes
3. Test thoroughly
4. Upload new AAB
5. Staged rollout (recommended)

## Support

For issues or questions:
- Check [Play Console Help](https://support.google.com/googleplay/android-developer)
- Review [Flutter Deployment Docs](https://flutter.dev/docs/deployment/android)
- Contact: [your-email@example.com]

## Notes

- Always test release builds before uploading
- Use staged rollouts for major updates
- Monitor crash reports regularly
- Keep app updated with latest Flutter and dependencies
- Follow Google Play policies and guidelines

