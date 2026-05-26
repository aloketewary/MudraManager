allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.application") version "8.13.2" apply false
    id("com.android.library") version "8.13.2" apply false
    kotlin("android") version "2.1.0" apply false
}


buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Add your buildscript dependencies here, e.g.,
        // classpath("com.android.tools.build:gradle:...")
        // classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:...")'
        classpath ("com.android.tools.build:gradle:8.13.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)
subprojects {
    buildDir = file("${rootProject.buildDir}/${project.name}")
    evaluationDependsOn(":app")
    configurations.all {
        resolutionStrategy {
            // home_widget uses "1.+" for glance which resolves to 1.3.0-alpha01
            // requiring compileSdk 37 + AGP 9.1.0. Pin to last compatible version.
            force("androidx.glance:glance-appwidget:1.1.1")
            force("androidx.glance:glance:1.1.1")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}