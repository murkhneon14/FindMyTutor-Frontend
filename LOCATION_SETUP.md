# Location System Setup Guide

This guide explains how to set up location permissions for the FindMyTutor app on Android and iOS.

## 📱 Android Setup

### 1. Update `android/app/src/main/AndroidManifest.xml`

Add the following permissions inside the `<manifest>` tag (before `<application>`):

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

### 2. Update Gradle Settings

In `android/app/build.gradle`, ensure your `minSdkVersion` is at least 21:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
        // ... other settings
    }
}
```

## 🍎 iOS Setup

### 1. Update `ios/Runner/Info.plist`

Add the following keys inside the `<dict>` tag:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to help you find nearby tutors</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location to help you find nearby tutors</string>
```

## 📦 Install Dependencies

Run the following command to install the new packages:

```bash
cd /home/parasareth/code/proffesional/flutter/fronted/FindMyTutor-Frontend
flutter pub get
```

## 🧪 Testing

### Test Location on Emulator

**Android Emulator:**
1. Open the emulator's extended controls (three dots menu)
2. Go to Location
3. Set a custom location (e.g., Delhi: 28.6139, 77.2090)

**iOS Simulator:**
1. Debug → Location → Custom Location
2. Enter latitude and longitude

### Test on Real Device

1. Enable location services on your device
2. Grant location permission when prompted
3. The app will automatically fetch your current location

## 🔧 Features Implemented

### Backend (Node.js/Express)
- ✅ Teacher profile creation with optional location
- ✅ Location validation (latitude: -90 to 90, longitude: -180 to 180)
- ✅ Edit teacher profile with location updates
- ✅ Geospatial search using MongoDB 2dsphere index
- ✅ Search nearby teachers by radius and subject
- ✅ Comprehensive error handling and logging

### Frontend (Flutter)
- ✅ Location service with permission handling
- ✅ Automatic location fetch on teacher signup
- ✅ Manual location refresh button
- ✅ Location status indicator
- ✅ Search nearby teachers with filters
- ✅ Radius slider (1-50 km)
- ✅ Subject filter
- ✅ Teacher cards with profile information

## 📝 API Endpoints

### Create Teacher Profile
```
POST /teacher-profile
{
  "phone": "1234567890",
  "gender": "male",
  "qualifications": "MSc Mathematics",
  "experience": "5",
  "subjects": ["Math"],
  "fees": 500,
  "timings": "Evening",
  "latitude": 28.6139,  // Optional
  "longitude": 77.2090  // Optional
}
```

### Update Teacher Location
```
PUT /teacher-profile
{
  "latitude": 28.6139,
  "longitude": 77.2090
}
```

### Search Nearby Teachers
```
POST /nearby-teachers
{
  "latitude": 28.6139,
  "longitude": 77.2090,
  "radius": 5,        // km
  "subject": "Math",  // Optional
  "page": 1,
  "limit": 10
}
```

## 🐛 Troubleshooting

### Location not working on Android
- Check if location services are enabled in device settings
- Verify permissions are granted in app settings
- Ensure Google Play Services is installed and updated

### Location not working on iOS
- Check if location services are enabled for the app
- Verify Info.plist has the required keys
- Reset location permissions: Settings → General → Reset → Reset Location & Privacy

### Backend errors
- Check MongoDB 2dsphere index is created: `db.teacherprofiles.getIndexes()`
- Verify coordinates are in correct format: [longitude, latitude]
- Check server logs for detailed error messages

## 🚀 Next Steps

1. Run `flutter pub get` to install dependencies
2. Update Android and iOS permission files
3. Test on emulator/simulator
4. Test on real device
5. Deploy backend changes

## 📚 Additional Resources

- [Geolocator Package](https://pub.dev/packages/geolocator)
- [Permission Handler Package](https://pub.dev/packages/permission_handler)
- [MongoDB Geospatial Queries](https://www.mongodb.com/docs/manual/geospatial-queries/)
