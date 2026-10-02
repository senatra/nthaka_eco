# Flutter engine and plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

-dontwarn io.flutter.embedding.**

# SQLite (sqflite)
-keep class com.tekartik.sqflite.** { *; }

# Play Core / deferred components (if used later)
-keep class com.google.android.play.core.** { *; }
