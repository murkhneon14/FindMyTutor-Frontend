@echo off
echo ========================================
echo Creating Keystore for FindMyTutor
echo ========================================
echo.

REM Check if Java is available
where java >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Java is not in PATH.
    echo.
    echo Please install Java JDK or use Android Studio's JDK:
    echo 1. Download from: https://adoptium.net/
    echo 2. OR use Android Studio's JDK (usually in Android Studio installation)
    echo.
    echo If you have Android Studio, find keytool.exe and run:
    echo "path\to\keytool.exe" -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass findmytutor2024 -keypass findmytutor2024 -dname "CN=FindMyTutor, OU=Development, O=FindMyTutor, L=City, ST=State, C=IN"
    echo.
    pause
    exit /b 1
)

echo Creating keystore: upload-keystore.jks
echo.

keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass findmytutor2024 -keypass findmytutor2024 -dname "CN=FindMyTutor, OU=Development, O=FindMyTutor, L=City, ST=State, C=IN"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo ✅ Keystore created successfully!
    echo ========================================
    echo.
    echo Keystore file: upload-keystore.jks
    echo Key alias: upload
    echo.
    echo ⚠️ IMPORTANT: Keep this keystore file safe!
    echo    You'll need it for all future Play Store updates.
    echo.
    echo Next steps:
    echo 1. Run: flutter build appbundle --release
    echo 2. Upload the AAB to Play Console
    echo.
) else (
    echo.
    echo ❌ ERROR: Failed to create keystore
    echo.
    echo Please check:
    echo 1. Java is installed and in PATH
    echo 2. You have write permissions in this directory
    echo.
)

pause

