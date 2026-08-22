# ==============================================================================
# Flutter & Android Core Rules
# ==============================================================================
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve general reflection attributes
-keepattributes SourceFile,LineNumberTable,*Annotation*,EnclosingMethod,Signature,Exceptions,InnerClasses

# Google Play Core & Deferred Components (optional Play Store dynamic features)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# ==============================================================================
# Jackson Databind & Core (Used by youtubedl-android)
# ==============================================================================
-keep class com.fasterxml.jackson.** { *; }
-keep interface com.fasterxml.jackson.** { *; }
-keep enum com.fasterxml.jackson.** { *; }
-dontwarn com.fasterxml.jackson.**
-keepnames class com.fasterxml.jackson.** { *; }

-keep @com.fasterxml.jackson.annotation.** class * { *; }
-keepclassmembers class * {
    @com.fasterxml.jackson.annotation.* *;
}
-keepclassmembers public final enum com.fasterxml.jackson.annotation.** {
    public static final ** *;
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
-keepclassmembers class ** extends com.fasterxml.jackson.databind.ser.std.** {
    public <init>(...);
}
-keepclassmembers class ** extends com.fasterxml.jackson.databind.deser.std.** {
    public <init>(...);
}

# ==============================================================================
# youtubedl-android, FFmpeg, Aria2c & Extractor Engine
# ==============================================================================
-keep class com.yausername.youtubedl_android.** { *; }
-keep interface com.yausername.youtubedl_android.** { *; }
-keep class com.yausername.ffmpeg.** { *; }
-keep interface com.yausername.ffmpeg.** { *; }
-keep class com.yausername.aria2c.** { *; }
-keep interface com.yausername.aria2c.** { *; }

-keep class com.ashishpipaliya.extractor.** { *; }
-keep interface com.ashishpipaliya.extractor.** { *; }

-dontwarn com.yausername.**
-dontwarn com.ashishpipaliya.extractor.**

# Apache Commons Compress (Used for zip/tar extraction by youtubedl-android)
-keep class org.apache.commons.compress.** { *; }
-dontwarn org.apache.commons.compress.**

# ==============================================================================
# Audio Service, Just Audio & Media Session
# ==============================================================================
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.audio_session.** { *; }
-dontwarn com.ryanheise.**

# ==============================================================================
# Kotlin Coroutines & Metadata
# ==============================================================================
-keep class kotlin.Metadata { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**
