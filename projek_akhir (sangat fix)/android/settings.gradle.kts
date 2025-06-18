pluginManagement {
    val flutterSdkPath = run {
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

// PENTING: Buat flutter properties tersedia untuk semua project
gradle.beforeProject {
    // Pastikan flutter extension tersedia untuk plugin geolocator_android
    if (project.name == "geolocator_android") {
        // Terapkan konfigurasi SDK secara eksplisit
        project.extra.apply {
            set("compileSdkVersion", 35)
            set("minSdkVersion", 21)
            set("targetSdkVersion", 35)
        }
        
        // Tambahkan extension android secara manual jika diperlukan
        project.extensions.extraProperties["android.compileSdkVersion"] = 35
        
        // Pastikan flutter tersedia
        val rootExtras = rootProject.extensions.extraProperties
        if (rootExtras.has("flutter.sdk")) {
            project.extensions.extraProperties["flutter.sdk"] = rootExtras["flutter.sdk"]
        }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.1.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.0" apply false
}

include(":app")

// Terapkan konfigurasi override ke plugin geolocator_android jika ditemukan
gradle.afterProject {
    if (project.name == "geolocator_android") {
        project.apply(from = "${rootProject.projectDir}/geolocator_android.gradle.kts")
    }
}

rootProject.name = "android"