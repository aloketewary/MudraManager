import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val keystoreStoreFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
val requiredSigningProperties = listOf(
    "storePassword",
    "keyPassword",
    "keyAlias",
)
val releaseSigningReady = keystorePropertiesFile.exists() &&
    requiredSigningProperties.all { keystoreProperties.getProperty(it)?.isNotBlank() == true } &&
    keystoreStoreFile?.isFile == true

val releaseTaskRequested = gradle.startParameter.taskNames.any { taskName ->
    taskName.contains("release", ignoreCase = true) ||
        taskName.contains("bundle", ignoreCase = true)
}
if (releaseTaskRequested && !releaseSigningReady) {
    throw GradleException(
        "Release signing is required. Configure android/key.properties " +
            "with storeFile, storePassword, keyAlias, and keyPassword " +
            "for a valid JKS before building or uploading an app bundle.",
    )
}
android {
    namespace = "com.mudramanager.app"
//    compileSdk = flutter.compileSdkVersion
//    ndkVersion = flutter.ndkVersion
    ndkVersion = "28.2.13676358"
    compileSdk = 36
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mudramanager.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
//        minSdk = flutter.minSdkVersion
        minSdk = 26
//        targetSdk = flutter.targetSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "version"
    productFlavors {
        create("prod") {
            dimension = "version"
            isDefault = true
        }
        create("dev") {
            dimension = "version"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
        }
    }

    signingConfigs {
        create("release") {
            if (releaseSigningReady) {
                storeFile = keystoreStoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        debug {
            versionNameSuffix = "-debug"
        }
        release {
            if (releaseSigningReady) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                file("proguard-rules.pro")
            )
        }
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
        }
    }


}

flutter {
    source = "../.."
}

dependencies {
    implementation(project(":integration_test"))
    implementation("androidx.core:core-ktx")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

    // Unit test dependencies
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.robolectric:robolectric:4.12.2")
    testImplementation("androidx.test:core:1.5.0")
    testImplementation("org.mockito.kotlin:mockito-kotlin:5.2.1")
    testImplementation("org.json:json:20231013")
}

