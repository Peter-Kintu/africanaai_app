plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "info.africanaai"
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
        applicationId = "info.africanaai"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keyAliasValue = project.findProperty("MY_APP_KEY_ALIAS") as String?
    val keyPasswordValue = project.findProperty("MY_APP_KEY_PASSWORD") as String?
    val storePasswordValue = project.findProperty("MY_APP_STORE_PASSWORD") as String?
    val releaseKeystoreFile = file("release.keystore")

    signingConfigs {
        create("release") {
            if (keyAliasValue == null || keyPasswordValue == null || storePasswordValue == null || !releaseKeystoreFile.exists()) {
                throw org.gradle.api.GradleException(
                    "Release signing is not configured. Add MY_APP_KEY_ALIAS, MY_APP_KEY_PASSWORD, MY_APP_STORE_PASSWORD to android/gradle.properties and place android/app/release.keystore in android/app/"
                )
            }
            keyAlias = keyAliasValue
            keyPassword = keyPasswordValue
            storeFile = releaseKeystoreFile
            storePassword = storePasswordValue
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs["release"]
        }
    }
}

flutter {
    source = "../.."
}
