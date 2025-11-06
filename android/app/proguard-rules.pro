# Flutter / Dart
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# OkHttp/Okio (used by many SDKs)
-dontwarn okhttp3.**
-dontwarn okio.**

# Razorpay
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Google Play Core / SplitCompat (Flutter deferred components)
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**

# Gson / JSON
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Kotlin metadata
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# Keep model classes (optional if obfuscation breaks JSON)
#-keep class com.findmytutor.** { *; }

