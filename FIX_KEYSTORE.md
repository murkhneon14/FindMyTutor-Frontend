# Fix Keystore Error - Quick Guide

## Problem
Build fails with: `Keystore file 'upload-keystore.jks' not found`

## Solution

### Step 1: Create Keystore

**Option A: Using PowerShell Script (Easiest)**
```powershell
cd android
.\create-keystore-simple.ps1
```

**Option B: Using Batch Script**
```batch
cd android
create-keystore-now.bat
```

**Option C: Manual Command**
```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass findmytutor2024 -keypass findmytutor2024 -dname "CN=FindMyTutor, OU=Development, O=FindMyTutor, L=City, ST=State, C=IN"
```

### Step 2: Verify Keystore Created

Check that `android/upload-keystore.jks` file exists.

### Step 3: Build Again

```bash
cd frontend/FindMyTutor-Frontend
flutter clean
flutter build appbundle --release
```

## If Java/Keytool Not Found

### Find Keytool Location

**Android Studio:**
```
C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe
```

**Java JDK:**
```
C:\Program Files\Java\jdk-XX\bin\keytool.exe
```

Then run:
```bash
"FULL_PATH_TO_KEYTOOL.exe" -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass findmytutor2024 -keypass findmytutor2024 -dname "CN=FindMyTutor, OU=Development, O=FindMyTutor, L=City, ST=State, C=IN"
```

## Current Configuration

- **Keystore file**: `android/upload-keystore.jks`
- **Key alias**: `upload`
- **Store password**: `findmytutor2024`
- **Key password**: `findmytutor2024`

## Important

- **Keep keystore safe!** You'll need it for all future updates
- **Backup the keystore** to a secure location
- **Never commit** keystore to git (already in .gitignore)

## After Creating Keystore

The build should now succeed and create a properly signed AAB file for Play Store upload.

