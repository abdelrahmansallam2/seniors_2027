plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.util.Base64

val seniorsPreview = (project.findProperty("dart-defines") as? String)
    ?.split(",")
    ?.any { String(Base64.getDecoder().decode(it), Charsets.UTF_8) == "SENIORS_PREVIEW=true" } == true

android {
    namespace = "com.seniors2027.app"
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
        applicationId = if (seniorsPreview) "com.seniors2027.app.preview" else "com.seniors2027.app"
        manifestPlaceholders["appLabel"] = if (seniorsPreview) "Seniors 2027 Preview" else "Seniors 2027"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val properties = Properties()
            val propertiesFile = rootProject.file("key.properties")
            if (propertiesFile.exists()) {
                properties.load(propertiesFile.inputStream())
                keyAlias = properties.getProperty("keyAlias") as String
                keyPassword = properties.getProperty("keyPassword") as String
                storePassword = properties.getProperty("storePassword") as String
                storeFile = properties.getProperty("storeFile")?.let { file(it) }
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
