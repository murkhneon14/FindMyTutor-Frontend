# Simple PowerShell script to create keystore
# Run this in the android folder

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Creating Keystore for FindMyTutor" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if keystore already exists
if (Test-Path "upload-keystore.jks") {
    Write-Host "⚠️ Keystore already exists!" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to overwrite it? (y/n)"
    if ($overwrite -ne "y") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit
    }
    Remove-Item "upload-keystore.jks" -Force
}

# Try to find keytool
$keytool = $null

# Check if Java is in PATH
try {
    $keytool = Get-Command keytool -ErrorAction Stop
    Write-Host "✅ Found keytool in PATH" -ForegroundColor Green
} catch {
    # Try common Java locations
    $javaPaths = @(
        "$env:JAVA_HOME\bin\keytool.exe",
        "C:\Program Files\Java\jdk-*\bin\keytool.exe",
        "C:\Program Files\Eclipse Adoptium\jdk-*\bin\keytool.exe",
        "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe",
        "${env:LOCALAPPDATA}\Android\Sdk\jdk\bin\keytool.exe"
    )
    
    foreach ($path in $javaPaths) {
        $files = Get-ChildItem -Path (Split-Path $path -Parent) -Filter "keytool.exe" -ErrorAction SilentlyContinue
        if ($files) {
            $keytool = $files[0]
            Write-Host "✅ Found keytool at: $($keytool.FullName)" -ForegroundColor Green
            break
        }
    }
}

if (-not $keytool) {
    Write-Host ""
    Write-Host "❌ ERROR: Java keytool not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please do one of the following:" -ForegroundColor Yellow
    Write-Host "1. Install Java JDK from: https://adoptium.net/" -ForegroundColor Yellow
    Write-Host "2. Add Java to your PATH" -ForegroundColor Yellow
    Write-Host "3. Use Android Studio's JDK (usually at: C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "If you have Android Studio, run this command manually:" -ForegroundColor Yellow
    Write-Host '  "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass findmytutor2024 -keypass findmytutor2024 -dname "CN=FindMyTutor, OU=Development, O=FindMyTutor, L=City, ST=State, C=IN"' -ForegroundColor Cyan
    Write-Host ""
    pause
    exit 1
}

Write-Host ""
Write-Host "Creating keystore..." -ForegroundColor Green
Write-Host ""

$keytoolPath = if ($keytool.GetType().Name -eq "ApplicationInfo") { $keytool.Source } else { $keytool.FullName }

& $keytoolPath -genkey -v `
    -keystore upload-keystore.jks `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -alias upload `
    -storepass findmytutor2024 `
    -keypass findmytutor2024 `
    -dname "CN=FindMyTutor, OU=Development, O=FindMyTutor, L=City, ST=State, C=IN"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✅ Keystore created successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Keystore file: upload-keystore.jks" -ForegroundColor Cyan
    Write-Host "Key alias: upload" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "⚠️ IMPORTANT: Keep this keystore file safe!" -ForegroundColor Yellow
    Write-Host "   You'll need it for all future Play Store updates." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Green
    Write-Host "1. Run: flutter build appbundle --release" -ForegroundColor Cyan
    Write-Host "2. Upload the AAB to Play Console" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ ERROR: Failed to create keystore" -ForegroundColor Red
    Write-Host ""
    pause
    exit 1
}

pause

