import java.util.Properties
import java.io.FileInputStream
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.findmytutor.app"
    // Explicit Play-ready API level (Policy target / compile parity). Keep >= Play requirements.
    compileSdk = flutter.compileSdkVersion.coerceAtLeast(35)
    ndkVersion = "27.0.12077973"
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Unique application ID for Play Store
        applicationId = "com.findmytutor.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23  // Required for Firebase
        targetSdk = flutter.targetSdkVersion.coerceAtLeast(35)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    // Configure signing from key.properties if available
    val keystorePropertiesFile = rootProject.file("key.properties")
    var useReleaseSigning = false
    val isReleaseBuildRequested = gradle.startParameter.taskNames.any {
        it.contains("Release", ignoreCase = true)
    }
    
    if (keystorePropertiesFile.exists()) {
        try {
            val keystoreProperties = Properties()
            keystoreProperties.load(FileInputStream(keystorePropertiesFile))
            val storeFileRelative = keystoreProperties["storeFile"] as String?
            
            if (storeFileRelative != null) {
                val keystoreFile = rootProject.file(storeFileRelative)
                val keystoreExists = keystoreFile.exists()
                
                if (keystoreExists) {
                    signingConfigs {
                        create("release") {
                            // Store file path relative to android folder (parent of app folder)
                            storeFile = keystoreFile
                            storePassword = keystoreProperties["storePassword"] as String
                            keyAlias = keystoreProperties["keyAlias"] as String
                            keyPassword = keystoreProperties["keyPassword"] as String
                        }
                    }
                    useReleaseSigning = true
                    println("✅ Release keystore found and configured")
                } else {
                    println("⚠️ WARNING: Keystore file not found: $storeFileRelative")
                    println("⚠️ Release build will use debug signing (NOT suitable for Play Store)")
                    println("⚠️ To create keystore, run: android\\create-keystore-now.bat")
                }
            }
        } catch (e: Exception) {
            println("⚠️ WARNING: Error reading key.properties: ${e.message}")
            println("⚠️ Release build will use debug signing")
        }
    } else {
        println("ℹ️ key.properties not found - using debug signing for release")
    }

    // Hard-stop release builds without a real upload key.
    if (isReleaseBuildRequested && !useReleaseSigning) {
        throw GradleException(
            "Release signing is not configured. Create android/key.properties from android/key.properties.example and set a valid .jks file before building release."
        )
    }

    buildTypes {
        release {
            if (useReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
            isDebuggable = false
            // Enable code shrinking and obfuscation for release
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    packaging {
        jniLibs {
            // Legacy packaging keeps extractNativeLibs behavior compatible with some plugins.
            // Do not force keepDebugSymbols here — it can break Flutter’s release strip on Windows/NDK.
            useLegacyPackaging = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation(platform("com.google.firebase:firebase-bom:34.8.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
}
