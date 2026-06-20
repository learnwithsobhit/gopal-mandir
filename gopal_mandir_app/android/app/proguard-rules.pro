# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Razorpay (reflection + JS interface heavy)
-keepattributes *Annotation*
-keepattributes JavascriptInterface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }
-optimizations !method/inlining/*
-keep class com.google.android.apps.nbu.paisa.inapp.client.api.** { *; }

# Parcelable CREATOR fields
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Annotations used by various plugins
-keep @interface * { *; }

# Flutter references Play Core (deferred components / split install) classes
# that we do not bundle. The app does not use deferred components, so it is
# safe to tell R8 to ignore them.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
