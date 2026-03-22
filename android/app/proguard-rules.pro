# Google ML Kit Text Recognition
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Mobile Scanner
-keep class com.google.zxing.** { *; }
-keep class com.journeyapps.barcodescanner.** { *; }

# NFC Manager
-keep class io.flutter.plugins.nfcmanager.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.** { *; }

# Home Widget
-keep class es.antonborri.home_widget.** { *; }

# General Flutter rules
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
