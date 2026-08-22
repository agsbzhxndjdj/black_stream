# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# InAppWebView
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keep class android.webkit.** { *; }

# Video Player
-keep class com.google.android.exoplayer2.** { *; }

# Hive
-keep class com.hivemq.client.** { *; }
-keep class io.hive.** { *; }

# General
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Don't warn about missing classes
-dontwarn android.net.http.*
-dontwarn org.apache.commons.codec.**
-dontwarn org.apache.http.**
