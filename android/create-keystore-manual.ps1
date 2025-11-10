# PowerShell script to create keystore for FindMyTutor
# Run this script in the android folder

Write-Host "Creating keystore for FindMyTutor app..." -ForegroundColor Green
Write-Host ""

# Try to find Java
$javaPaths = @(
    "$env:JAVA_HOME\bin\keytool.exe",
    "C:\Program Files\Java\jdk-*\bin\keytool.exe",
    "C:\Program Files\Eclipse Adoptium\jdk-*\bin\keytool.exe",
    "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe",
    "C:\Program Files\Android\Android Studio\jre\bin\keytool.exe"
)

$keytoolPath = $null
foreach ($pattern in $javaPaths) {
    $found = Get-ChildItem -Path (Split-Path $pattern -Parent) -Filter (Split-Path $pattern -Leaf) -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $keytoolPath = $found.FullName
        break
    }
}

if (-not $keytoolPath) {
    Write-Host "ERROR: Java keytool not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Java JDK from: https://adoptium.net/" -ForegroundColor Yellow
    Write-Host "Or if you have Android Studio, use its JDK:" -ForegroundColor Yellow
    Write-Host "  C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "After installing Java, run this script again." -ForegroundColor Yellow
    exit 1
}

Write-Host "Found Java keytool at: $keytoolPath" -ForegroundColor Green
Write-Host ""

# Create keystore
$keystorePath = Join-Path $PSScriptRoot "upload-keystore.jks"
if (Test-Path $keystorePath) {
    Write-Host "Keystore already exists at: $keystorePath" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to overwrite it? (y/n)"
    if ($overwrite -ne "y") {
        Write-Host "Keystore creation cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "Creating keystore..." -ForegroundColor Green
& $keytoolPath -genkey -v -keystore $keystorePath -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass findmytutor2024 -keypass findmytutor2024 -dname "CN=FindMyTutor, OU=Development, O=FindMyTutor, L=City, ST=State, C=IN"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Keystore created successfully!" -ForegroundColor Green
    Write-Host "Location: $keystorePath" -ForegroundColor Green
    Write-Host ""
    Write-Host "IMPORTANT: Keep this keystore file safe!" -ForegroundColor Yellow
    Write-Host "You'll need it for all future Play Store updates." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "ERROR: Failed to create keystore" -ForegroundColor Red
    exit 1
}


