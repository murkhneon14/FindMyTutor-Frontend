# Firebase Cloud Messaging (FCM) Setup Guide

This guide will help you set up Firebase Cloud Messaging for push notifications in your FindMyTutor app.

## 📋 Prerequisites

- Firebase account (free)
- Flutter project
- Node.js backend

---

## 🔥 Part 1: Firebase Console Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: `FindMyTutor` (or your preferred name)
4. Disable Google Analytics (optional)
5. Click **"Create project"**

### Step 2: Add Android App

1. In Firebase Console, click **"Add app"** → Select **Android**
2. Enter package name: `com.example.find_my_tutor`
   - Find this in `android/app/build.gradle` under `applicationId`
3. Download `google-services.json`
4. Place it in: `FindMyTutor-Frontend/android/app/google-services.json`

### Step 3: Add iOS App

1. In Firebase Console, click **"Add app"** → Select **iOS**
2. Enter bundle ID: `com.example.findMyTutor`
   - Find this in Xcode or `ios/Runner.xcodeproj/project.pbxproj`
3. Download `GoogleService-Info.plist`
4. Place it in: `FindMyTutor-Frontend/ios/Runner/GoogleService-Info.plist`

### Step 4: Get Service Account Key (Backend)

1. In Firebase Console → **Project Settings** → **Service Accounts**
2. Click **"Generate new private key"**
3. Download the JSON file
4. Rename it to `serviceAccountKey.json`
5. Place it in: `backend/findmy-tutor-backend/serviceAccountKey.json`
6. **⚠️ IMPORTANT**: Add to `.gitignore` to keep it secret!

---

## 📱 Part 2: Android Configuration

### Step 1: Update `android/build.gradle`

Add Google services classpath:

```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

### Step 2: Update `android/app/build.gradle`

Add at the **bottom** of the file:

```gradle
apply plugin: 'com.google.gms.google-services'
```

### Step 3: Update `android/app/src/main/AndroidManifest.xml`

Already done! The `POST_NOTIFICATIONS` permission is added.

---

## 🍎 Part 3: iOS Configuration

### Step 1: Enable Push Notifications in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** → **Signing & Capabilities**
3. Click **"+ Capability"**
4. Add **"Push Notifications"**
5. Add **"Background Modes"** and check:
   - ✅ Remote notifications

### Step 2: Upload APNs Certificate to Firebase

1. Generate APNs certificate in Apple Developer Portal
2. Upload to Firebase Console → **Project Settings** → **Cloud Messaging** → **APNs Certificates**

---

## 🛠️ Part 4: Flutter CLI Setup

### Step 1: Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### Step 2: Configure Firebase for Flutter

```bash
cd FindMyTutor-Frontend
flutterfire configure
```

This will:
- Create `lib/firebase_options.dart` automatically
- Link your Flutter app to Firebase project
- Configure Android and iOS apps

**Select your Firebase project when prompted**

---

## 🔧 Part 5: Backend Setup

### Step 1: Install Dependencies

Already done! `firebase-admin` is being installed.

### Step 2: Add Service Account Key

Make sure `serviceAccountKey.json` is in the backend root directory.

### Step 3: Update `.gitignore`

Add to `backend/findmy-tutor-backend/.gitignore`:

```
serviceAccountKey.json
```

---

## 🚀 Part 6: Testing

### Step 1: Run Backend

```bash
cd backend/findmy-tutor-backend
npm run dev
```

You should see:
```
✅ Firebase Admin SDK initialized successfully
```

### Step 2: Run Flutter App

```bash
cd FindMyTutor-Frontend
flutter pub get
flutter run
```

### Step 3: Login and Send FCM Token

After logging in, the app will automatically:
1. Request notification permissions
2. Get FCM token
3. Send token to backend

Check console for:
```
📱 FCM Token: <your-token>
✅ FCM token sent to server successfully
```

### Step 4: Test Push Notification

1. Open app on Device A (logged in as User A)
2. Send a message to User A from Device B (or backend)
3. Close/minimize app on Device A
4. You should receive a push notification! 🎉

---

## 🔍 Troubleshooting

### No FCM Token Generated

- Check if Firebase is initialized: Look for initialization logs
- Verify `google-services.json` and `GoogleService-Info.plist` are in correct locations
- Run `flutterfire configure` again

### Notifications Not Received

- Check if FCM token was sent to backend
- Verify `serviceAccountKey.json` is in backend root
- Check backend logs for FCM errors
- Make sure user has granted notification permissions

### Android Build Errors

- Ensure `google-services.json` is in `android/app/`
- Check `android/build.gradle` has Google services classpath
- Check `android/app/build.gradle` has `apply plugin: 'com.google.gms.google-services'`

### iOS Build Errors

- Ensure `GoogleService-Info.plist` is added to Xcode project
- Check Push Notifications capability is enabled
- Verify APNs certificate is uploaded to Firebase

---

## 📚 API Endpoints

### Update FCM Token
```
POST /api/user/fcm-token
Body: { "userId": "...", "fcmToken": "..." }
```

### Remove FCM Token (Logout)
```
DELETE /api/user/fcm-token
Body: { "userId": "..." }
```

---

## 🎯 Features Implemented

✅ **FCM push notifications** for new messages  
✅ **Works when app is closed** (true push notifications)  
✅ **Automatic token management** (send on login, remove on logout)  
✅ **Foreground notifications** (when app is open)  
✅ **Background notifications** (when app is minimized)  
✅ **Terminated state notifications** (when app is completely closed)  
✅ **Smart delivery** (only send to offline users)  
✅ **Notification tap handling** (navigate to chat)

---

## 🔐 Security Notes

- **Never commit** `serviceAccountKey.json` to Git
- **Never commit** `google-services.json` or `GoogleService-Info.plist` if they contain sensitive data
- Store FCM tokens securely in your database
- Validate user permissions before sending notifications

---

## 📖 Next Steps

1. Complete Firebase setup following this guide
2. Test notifications on real devices
3. Implement notification tap navigation to specific chats
4. Add notification badges and sounds
5. Implement notification preferences (mute chats, etc.)

---

## 🆘 Need Help?

- [Firebase Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)

---

**Happy Coding! 🚀**
