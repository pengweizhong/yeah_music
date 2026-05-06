import java.util.Properties
import java.io.FileInputStream

// 加载 key.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.pengwz.yeah_music"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.pengwz.yeah_music"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // flutter_appauth 合并清单时使用 ${appAuthRedirectScheme}，须与 Azure 重定向 URI 的 scheme 一致
        manifestPlaceholders["appAuthRedirectScheme"] = "com.pengwz.yeahmusic"
    }

    //  必须先声明 signingConfigs, 允许debug下使用
    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties["storeFile"]?.toString()
            val storePasswordValue = keystoreProperties["storePassword"]?.toString()
            val keyAliasValue = keystoreProperties["keyAlias"]?.toString()
            val keyPasswordValue = keystoreProperties["keyPassword"]?.toString()

            if (storeFilePath != null &&
                storePasswordValue != null &&
                keyAliasValue != null &&
                keyPasswordValue != null
            ) {
                storeFile = file(storeFilePath)
                storePassword = storePasswordValue
                keyAlias = keyAliasValue
                keyPassword = keyPasswordValue
            } else {
                println("⚠️ Warning: Missing keystore config, using debug signing.")
            }
        }
    }


    //  再声明 buildTypes
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
