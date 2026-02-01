# Play Store Deployment Checklist

## Pre-Deployment Checklist

### 1. App Signing ✅
- [ ] Create a release keystore (if not exists)
- [ ] Copy `key.properties.template` to `key.properties`
- [ ] Fill in keystore credentials in `key.properties`
- [ ] Place `keystore.jks` in `android/` directory
- [ ] Verify `key.properties` and `keystore.jks` are in `.gitignore`

### 2. Version Information
- [ ] Update version in `pubspec.yaml` (current: 1.0.1+3)
- [ ] Increment version code for each release
- [ ] Update version name following semantic versioning

### 3. App Icons
- [ ] Verify app icon exists in all mipmap folders
- [ ] Test icon on different screen densities
- [ ] Ensure adaptive icon is configured (if using)

### 4. Permissions
- [ ] Review all permissions in AndroidManifest.xml
- [ ] Add permission descriptions in Play Console
- [ ] Test app with permissions denied
- [ ] Verify runtime permission requests work correctly

### 5. Build Configuration
- [ ] Verify `minSdk` is set to 23 (Android 6.0+)
- [ ] Verify `targetSdk` is up to date
- [ ] Enable ProGuard/R8 for release builds
- [ ] Test release build thoroughly

### 6. Privacy & Security
- [ ] Add Privacy Policy URL
- [ ] Complete Data Safety section in Play Console
- [ ] Review data collection practices
- [ ] Ensure sensitive data is encrypted
- [ ] Remove any hardcoded API keys or secrets

### 7. Testing
- [ ] Test on multiple Android versions (6.0+)
- [ ] Test on different screen sizes
- [ ] Test with poor network conditions
- [ ] Test all payment flows (Razorpay)
- [ ] Test location services
- [ ] Test notifications
- [ ] Test chat functionality
- [ ] Test subscription flows

### 8. Content
- [ ] App name: FindMyTutor
- [ ] Short description (80 characters max)
- [ ] Full description (4000 characters max)
- [ ] Screenshots (at least 2, up to 8)
- [ ] Feature graphic (1024 x 500)
- [ ] App icon (512 x 512)

### 9. Store Listing
- [ ] Category: Education
- [ ] Content rating questionnaire completed
- [ ] Target audience defined
- [ ] Contact email provided
- [ ] Website URL (if applicable)
- [ ] Privacy Policy URL

### 10. Release
- [ ] Create internal testing track
- [ ] Upload AAB (Android App Bundle) to internal testing
- [ ] Test with internal testers
- [ ] Create closed testing track
- [ ] Upload to closed testing
- [ ] Gradually roll out to production (start with 20%)

## Build Commands

### Build Release AAB
```bash
cd android
flutter build appbundle --release
```

### Build Release APK (for testing)
```bash
flutter build apk --release
```

### Verify AAB
```bash
bundletool build-apks --bundle=app-release.aab --output=app.apks
```

## Data Safety Requirements

### Data Collected
- **Location**: Approximate location (for finding nearby tutors/students)
- **Personal Info**: Name, email, phone number
- **Payment Info**: Processed by Razorpay (not stored locally)

### Data Shared
- Location data shared with other users (with consent)
- Profile information shared with other users

### Data Security
- Data encrypted in transit (HTTPS)
- Authentication required for sensitive operations
- Payment processing handled by secure third-party (Razorpay)

## Common Issues

### Issue: App crashes on release build
**Solution**: Check ProGuard rules, test with `--release` flag

### Issue: Permissions not working
**Solution**: Verify runtime permission requests, check AndroidManifest.xml

### Issue: Notifications not working
**Solution**: Verify FCM configuration, check notification permissions

### Issue: Location not working
**Solution**: Verify location permissions, test on real device

## Resources

- [Play Console](https://play.google.com/console)
- [App Bundle Guide](https://developer.android.com/guide/app-bundle)
- [Data Safety](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Content Rating](https://support.google.com/googleplay/android-developer/answer/9888170)

## Notes

- Always test release builds before uploading
- Use staged rollouts (start with 20%)
- Monitor crash reports in Play Console
- Respond to user reviews promptly
- Keep app updated regularly

