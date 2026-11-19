# Flutter ProGuard / R8 Rules for Maximum Optimization & Safety
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.plugins.** { *; }

# Preserve reflection attributes & annotations required by SDKs
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Play Core & Deferred Components dontwarn rules for R8
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-keep class com.google.android.play.core.appupdate.** { *; }
-keep class com.google.android.play.core.install.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class de.ffuf.in_app_update.** { *; }

# Firebase preservation
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
