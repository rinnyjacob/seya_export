plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.seya.expert"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"
    buildFeatures {
        buildConfig = true
    }

    packaging {
        resources.excludes.add("META-INF/*")
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.seya.expert"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
//        minSdk = flutter.minSdkVersion
//        minSdk = flutter.minSdkVersion
//        minSdk = flutter.minSdkVersion
//        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Split APK by ABI to reduce size - each device gets only what it needs
        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a"))
        }
    }

    buildTypes {
        release {
            // Enable code shrinking, obfuscation, and optimization
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Split APK by ABI - generates separate APKs for each architecture
    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a")
            isUniversalApk = true  // Also generate a universal APK
        }
    }




}


flutter {
    source = "../.."
//    disableDeferredComponents = true
}

dependencies {
    dependencies {
        implementation("com.google.android.play:app-update:2.1.0")
        implementation("com.google.android.play:feature-delivery:2.1.0")
    }
}
//dependencies {
//    // ...existing dependencies...
//    implementation("com.google.android.play:core:1.10.3")
//
////    implementation("com.google.android.play:core:1.10.3") {
////        exclude(group = "com.google.android.play", module = "core-common")
////    }
//}
