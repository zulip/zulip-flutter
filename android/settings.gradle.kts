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
    // Above the 9.3.1 in Flutter's app template
    // (`templateAndroidGradlePluginVersion` in the gradle_utils.dart
    // linked below), because lint in AGP 9.3.1 crashes when Gradle runs
    // on JDK 17, as it does in our CI. AGP 9.3.2 fixed that:
    //   https://issuetracker.google.com/issues/522845800
    // Once the template has 9.3.2 or later, go back to its version.
    id("com.android.application") version "9.3.3" apply false
    // Generally keep this at the version in Flutter's app template,
    // which is `templateKotlinGradlePluginVersion` in:
    //   https://github.com/flutter/flutter/blob/main/packages/flutter_tools/lib/src/android/gradle_utils.dart
    id("org.jetbrains.kotlin.android") version "2.4.20" apply false
}

include(":app")
