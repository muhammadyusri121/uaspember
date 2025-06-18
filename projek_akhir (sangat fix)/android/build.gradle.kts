buildscript {
    // Definisikan SDK versions secara global
    extra.apply {
        set("compileSdkVersion", 35)
        set("minSdkVersion", 21)
        set("targetSdkVersion", 35)
    }
    
    extra["flutter.sdk"] = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        properties.getProperty("flutter.sdk") 
            ?: throw GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
    }

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Buat flutter SDK tersedia ke semua subprojects
    extra["flutter.sdk"] = rootProject.extra["flutter.sdk"]
    
    // Ekstrak properti SDK untuk digunakan plugin
    extra["compileSdkVersion"] = rootProject.extra["compileSdkVersion"]
    extra["minSdkVersion"] = rootProject.extra["minSdkVersion"] 
    extra["targetSdkVersion"] = rootProject.extra["targetSdkVersion"]
}

val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}