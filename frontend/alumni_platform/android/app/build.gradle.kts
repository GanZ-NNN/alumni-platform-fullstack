plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.alumni_platform"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.alumni_platform"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
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

flutter {
    source = "../.."
}
// ວາງໃສ່ລຸ່ມສຸດຂອງໄຟລ໌ android/app/build.gradle.kts
configurations.all {
    resolutionStrategy {
        // ບັງຄັບໃຫ້ໃຊ້ Library ເວີຊັນທີ່ເກົ່າລົງໜ້ອຍໜຶ່ງ ເພື່ອໃຫ້ Build ຜ່ານໃນ AGP 8.2.2
        force("androidx.activity:activity:1.8.0")
        force("androidx.core:core:1.12.0")
        force("androidx.core:core-ktx:1.12.0")
        force("androidx.navigationevent:navigationevent-android:1.0.0-alpha01")
    }
}

// ປິດການກວດສອບ Metadata ເພາະ Library ໃໝ່ພະຍາຍາມບັງຄັບໃຫ້ເຮົາອັບ AGP ເປັນ 8.9.1
tasks.withType<com.android.build.gradle.internal.tasks.CheckAarMetadataTask> {
    enabled = false
}