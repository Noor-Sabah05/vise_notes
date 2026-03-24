plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // FIX: Set to 36 as required by your plugins
    namespace = "com.example.vise_notes"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.vise_notes"
        minSdk = flutter.minSdkVersion
        // FIX: Match targetSdk to compileSdk for best compatibility
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // This helps resolve the 'Unresolved reference embedding' in MainActivity.kt
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
}
