@echo off
echo Creating keystore for FindMyTutor app...
echo.

REM Check if Java is available
where java >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Java is not in PATH. Please install Java JDK or add it to PATH.
    echo.
    echo You can download Java from: https://adoptium.net/
    echo.
    pause
    exit /b 1
)

REM Create keystore
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass findmytutor2024 -keypass findmytutor2024 -dname "CN=FindMyTutor, OU=Development, O=FindMyTutor, L=City, ST=State, C=IN"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Keystore created successfully!
    echo.
    echo Now create key.properties file with:
    echo storePassword=findmytutor2024
    echo keyPassword=findmytutor2024
    echo keyAlias=upload
    echo storeFile=upload-keystore.jks
    echo.
) else (
    echo.
    echo ERROR: Failed to create keystore
    echo.
)

pause

