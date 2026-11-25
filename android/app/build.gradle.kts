import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.fittrace.app"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.fittrace.app"
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val isReleaseTask = gradle.startParameter.taskNames.any {
                it.contains("Release", ignoreCase = true)
            }
            val keyAliasProp = keystoreProperties.getProperty("keyAlias")?.trim()
            val keyPasswordProp = keystoreProperties.getProperty("keyPassword")?.trim()
            val storeFileProp = keystoreProperties.getProperty("storeFile")?.trim()
            val storePasswordProp = keystoreProperties.getProperty("storePassword")?.trim()

            if (!storeFileProp.isNullOrBlank() &&
                !storePasswordProp.isNullOrBlank() &&
                !keyAliasProp.isNullOrBlank() &&
                !keyPasswordProp.isNullOrBlank()
            ) {
                val resolvedStore = file(storeFileProp).takeIf { it.exists() }
                    ?: rootProject.file(storeFileProp).takeIf { it.exists() }
                if (resolvedStore != null) {
                    storeFile = resolvedStore
                    storePassword = storePasswordProp
                    keyAlias = keyAliasProp
                    keyPassword = keyPasswordProp
                } else if (isReleaseTask) {
                    throw org.gradle.api.GradleException(
                        "Release keystore file not found at '$storeFileProp'. Configure android/key.properties before building release."
                    )
                }
            } else if (isReleaseTask) {
                throw org.gradle.api.GradleException(
                    "Missing release signing credentials in android/key.properties (storeFile, storePassword, keyAlias, keyPassword)."
                )
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.work:work-runtime-ktx:2.9.1")
}
