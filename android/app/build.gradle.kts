plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.linkie.linkie_mo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.linkie.linkie_mo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // CI (Codemagic): keystore được decode từ env var vào CM_KEYSTORE_PATH
            // Local: dùng file upload-keystore.jks trong thư mục app
            val cmKeystorePath = System.getenv("CM_KEYSTORE_PATH")
            val localKeystore = file("upload-keystore.jks")

            if (cmKeystorePath != null && file(cmKeystorePath).exists()) {
                storeFile = file(cmKeystorePath)
                storePassword = System.getenv("CM_KEYSTORE_PASSWORD") ?: "linkie123456"
                keyAlias = System.getenv("CM_KEY_ALIAS") ?: "upload"
                keyPassword = System.getenv("CM_KEY_PASSWORD") ?: "linkie123456"
            } else if (localKeystore.exists()) {
                storeFile = localKeystore
                storePassword = "linkie123456"
                keyAlias = "upload"
                keyPassword = "linkie123456"
            }
        }
    }

    buildTypes {
        release {
            val releaseConfig = signingConfigs.findByName("release")
            signingConfig = if (releaseConfig?.storeFile?.exists() == true) {
                releaseConfig
            } else {
                // Fallback: dùng debug signing nếu không có keystore
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
