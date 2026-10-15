pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
    // Firebase Cloud Messaging: plugin Google Services membaca
    // `android/app/google-services.json` (project ID, sender ID, API key).
    // Didaftarkan di sini TAPI hanya `apply` di app/build.gradle.kts bila
    // berkasnya ada, supaya project tetap bisa di-build sebelum Firebase
    // dikonfigurasi (aplikasi otomatis turun ke kanal push tiruan).
    id("com.google.gms.google-services") version "4.4.4" apply false
}

include(":app")
