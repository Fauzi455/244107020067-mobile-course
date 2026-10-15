plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.polinema.jti.week6_campus_notify"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // WAJIB untuk flutter_local_notifications 22.x: plugin memakai API
        // java.time yang hanya ada di Android 8+ (API 26). Desugaring
        // menurunkannya ke perangkat lama tanpa menaikkan minSdk.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.polinema.jti.week6_campus_notify"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Syarat minimum plugin Minggu 6: firebase_messaging butuh API 21+,
        // flutter_secure_storage butuh API 23+ (Keystore/EncryptedShared
        // Preferences). Default Flutter saat ini (24) sudah memenuhi keduanya,
        // jadi nilainya dibiarkan mengikuti `flutter.minSdkVersion` — jangan
        // diturunkan di bawah 23.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Pasangan dari `isCoreLibraryDesugaringEnabled` di atas.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}

// ---------------------------------------------------------------------------
// Firebase Cloud Messaging (opsional saat pengembangan).
//
// Plugin Google Services MENGHARUSKAN berkas `android/app/google-services.json`
// ada. Kalau dipasang tanpa syarat, `flutter run`/`flutter build apk` langsung
// gagal hanya karena Firebase belum didaftarkan — padahal aplikasi ini sengaja
// dirancang tetap jalan dengan kanal push tiruan saat Firebase tidak tersedia
// (lihat `firebaseReady` di lib/main.dart).
//
// Karena itu plugin hanya di-apply BILA berkasnya ada:
//   * belum ada  -> build normal, push memakai SimulatedPushService;
//   * sudah ada  -> FCM sungguhan aktif tanpa perlu mengubah berkas ini lagi.
// ---------------------------------------------------------------------------
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
    logger.lifecycle("google-services.json ditemukan — FCM sungguhan diaktifkan.")
} else {
    logger.lifecycle(
        "google-services.json belum ada — plugin Google Services dilewati, " +
            "aplikasi memakai kanal push tiruan."
    )
}
