
# Ignore missing annotations - safe to skip
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn javax.annotation.concurrent.**
# Ignore Google HTTP Client and Joda Time warnings from Tink
-dontwarn com.google.api.client.**
-dontwarn com.google.crypto.tink.util.KeysDownloader
-dontwarn org.joda.time.**
# Suppress missing classes from Play Core Dynamic Delivery
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn com.google.crypto.tink.**
-dontwarn kotlin.**


# Optional: Keep Tink crypto classes (if using Firebase Auth, Tink, etc.)
-keep class com.google.crypto.tink.** { *; }
# Keep all Flutter and Kotlin related code
-keep class io.flutter.** { *; }
-keep class kotlinx.** { *; }
-keep class kotlin.** { *; }
# Keep crypto Tink classes (but suppress errors)
-keep class com.google.crypto.tink.** { *; }

-keep class com.google.android.play.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class com.shounakmulay.telephony.** { *; }
