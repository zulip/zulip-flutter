import java.io.FileNotFoundException
import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { reader ->
        localProperties.load(reader)
    }
}

val keystoreProperties: Properties? = try {
    Properties().apply {
        rootProject.file("release-keystore.properties").inputStream().use { load(it) }
    }
} catch (ignored: FileNotFoundException) {
    null
}

android {
    namespace = "com.zulip.flutter"

    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    defaultConfig {
        applicationId = "com.zulipmobile"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // These are synced to local.properties from pubspec.yaml by the flutter tool.
        versionCode = localProperties.getProperty("flutter.versionCode").toInt()
        versionName = localProperties.getProperty("flutter.versionName")

        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
    }

    signingConfigs {
        create("release") {
            if (project.hasProperty("signed")) {
                if (keystoreProperties == null) {
                    throw GradleException(
                            "Missing signing config, but signing requested (-Psigned).  Did you want an unsigned build?")
                }
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                if (!storeFile!!.exists()) {
                    throw GradleException(
                            "Keystore file missing, but signing requested (-Psigned).  Did you want an unsigned build?")
                }
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (project.hasProperty("signed"))
                    signingConfigs.getByName("release") else signingConfigs.getByName("debug")
        }
    }

    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }

    lint {
        // For docs on options available here:
        //   https://developer.android.com/reference/tools/gradle-api/8.5/com/android/build/api/dsl/Lint
        checkAllWarnings = true
        warningsAsErrors = true
        baseline = file("lint-baseline.xml")
        disable += "AndroidGradlePluginVersion"
        disable += "GradleDependency"
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
    }
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile>().configureEach {
    // Compile Kotlin with `-Werror`... but only in release builds, so that it
    // doesn't get in the way of quick local experiments for debugging.
    //
    // The string-searching makes this a bit of a mess, but it works.
    // Better would be if we can add this to android.buildTypes.release above;
    // but on a first attempt that didn't work (it affected debug builds too).
    compilerOptions.allWarningsAsErrors = name.contains("Release")
}

flutter {
    source = "../.."
}

dependencies {
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}
