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
    // Generally update this to the version found in recent releases
    // of Android Studio, as listed in this table:
    //   https://kotlinlang.org/docs/releases.html#release-details
    // A helpful discussion is at:
    //   https://stackoverflow.com/a/74425347
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
