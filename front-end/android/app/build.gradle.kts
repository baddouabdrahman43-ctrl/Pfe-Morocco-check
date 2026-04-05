plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.moroccocheck.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    flavorDimensions += "environment"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            val storeFilePath = providers.gradleProperty("MOROCCOCHECK_UPLOAD_STORE_FILE").orNull
            val storePasswordValue = providers.gradleProperty("MOROCCOCHECK_UPLOAD_STORE_PASSWORD").orNull
            val keyAliasValue = providers.gradleProperty("MOROCCOCHECK_UPLOAD_KEY_ALIAS").orNull
            val keyPasswordValue = providers.gradleProperty("MOROCCOCHECK_UPLOAD_KEY_PASSWORD").orNull

            if (!storeFilePath.isNullOrBlank() &&
                !storePasswordValue.isNullOrBlank() &&
                !keyAliasValue.isNullOrBlank() &&
                !keyPasswordValue.isNullOrBlank()
            ) {
                storeFile = file(storeFilePath)
                storePassword = storePasswordValue
                keyAlias = keyAliasValue
                keyPassword = keyPasswordValue
            }
        }
    }

    defaultConfig {
        applicationId = "com.moroccocheck.app"
        manifestPlaceholders["appLabel"] = "MoroccoCheck"
        manifestPlaceholders["allowCleartextTraffic"] = true
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    productFlavors {
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            manifestPlaceholders["appLabel"] = "MoroccoCheck Staging"
            manifestPlaceholders["allowCleartextTraffic"] = true
        }

        create("production") {
            dimension = "environment"
            manifestPlaceholders["appLabel"] = "MoroccoCheck"
            manifestPlaceholders["allowCleartextTraffic"] = false
        }
    }

    buildTypes {
        release {
            val hasReleaseSigning =
                !providers.gradleProperty("MOROCCOCHECK_UPLOAD_STORE_FILE").orNull.isNullOrBlank() &&
                !providers.gradleProperty("MOROCCOCHECK_UPLOAD_STORE_PASSWORD").orNull.isNullOrBlank() &&
                !providers.gradleProperty("MOROCCOCHECK_UPLOAD_KEY_ALIAS").orNull.isNullOrBlank() &&
                !providers.gradleProperty("MOROCCOCHECK_UPLOAD_KEY_PASSWORD").orNull.isNullOrBlank()

            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
