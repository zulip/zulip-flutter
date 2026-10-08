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
    id("com.android.application") version "8.12.0" apply false
    // Generally keep this at the version in Flutter's app template,
    // which is `templateKotlinGradlePluginVersion` in:
    //   https://github.com/flutter/flutter/blob/main/packages/flutter_tools/lib/src/android/gradle_utils.dart
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
