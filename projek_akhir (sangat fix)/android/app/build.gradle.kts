plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.projek_akhir"
    
    // Update ke SDK 35 atau lebih tinggi untuk mengatasi error
    compileSdk = 35  // Ubah ke versi 35
    
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.projek_akhir"
        minSdk = 21  // Tetapkan secara eksplisit untuk plugin geolocator
        targetSdk = 35  // Perbarui targetSdk ke 35 juga
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

// Tambahkan dependensi yang diperlukan
dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
}