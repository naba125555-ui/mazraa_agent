import java.util.Properties
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}
val signing = Properties()
val signingFile = rootProject.file("key.properties")
if (signingFile.exists()) signingFile.inputStream().use { signing.load(it) }
android {
    namespace = "com.mazraa.agent"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }
    defaultConfig {
        applicationId = "com.mazraa.agent"
        minSdk = maxOf(24, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    packaging { jniLibs { useLegacyPackaging = true } }
    signingConfigs {
        create("release") {
            if (signingFile.exists()) {
                keyAlias = signing.getProperty("keyAlias")
                keyPassword = signing.getProperty("keyPassword")
                storeFile = file(signing.getProperty("storeFile"))
                storePassword = signing.getProperty("storePassword")
            }
        }
    }
    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = if (signingFile.exists()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
        }
    }
}
flutter { source = "../.." }
