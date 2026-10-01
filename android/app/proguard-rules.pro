# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# app_links
-keep class com.llfbandit.app_links.** { *; }

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# home_widget
-keep class es.antonborri.home_widget.** { *; }

# sqlite3 (Drift)
-keep class com.simolus3.sqlite3.** { *; }

# ota_update (aggiornamento in-app)
-keep class sk.fourq.otaupdate.** { *; }

# package_info_plus
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }

# Google Play Core (Deferred Components warning fix)
-dontwarn com.google.android.play.core.**
