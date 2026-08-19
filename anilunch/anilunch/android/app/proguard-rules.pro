# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Supabase / Realtime / Postgrest
-keep class io.github.jan.supabase.** { *; }
-keep class io.ktor.** { *; }
-dontwarn io.ktor.**

# OkHttp (used by Supabase under the hood)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Kotlin Coroutines & Serialization
-keep class kotlinx.coroutines.** { *; }
-keep class kotlinx.serialization.** { *; }
-dontwarn kotlinx.serialization.**

# Dart / JNI bridge
-keep class com.google.** { *; }
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# Keep all annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Video Player
-keep class io.flutter.plugins.videoplayer.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Image picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }
