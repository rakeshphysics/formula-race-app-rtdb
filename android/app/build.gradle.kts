import java.util.Properties // <--- This line is correct

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.16.0"))
    implementation("com.google.firebase:firebase-database-ktx") // <--- ADD THIS LINE
    implementation("com.google.firebase:firebase-auth-ktx")

    // TODO: Add the dependencies for Firebase products you want to use
    // When using the BoM, don't specify versions in Firebase dependencies
    implementation("com.google.firebase:firebase-analytics")
    implementation("androidx.multidex:multidex:2.0.1")

    // Add the dependencies for any other desired Firebase products
    // https://firebase.google.com/docs/android/setup#available-libraries
}

// Load keystore properties
// Corrected: Uses 'Properties()' directly because of the import statement
val keystoreProperties = Properties()
val keystorePropertiesFile = file("../key.properties") // <-- Change this line
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use {
        keystoreProperties.load(it)
    }
   // println("✅ DEBUG: key.properties loaded. storeFile = ${keystoreProperties.getProperty("storeFile")}")
} else {
    // >>> MODIFIED LINE BELOW <<<
   // println("❌ DEBUG: key.properties file DOES NOT EXIST at ${keystorePropertiesFile.absolutePath}")
}

android {
    namespace = "com.physicswithrakesh.formularacing" // Your updated application ID
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
        applicationId = "com.physicswithrakesh.formularacing" // Your updated application ID
        minSdk = flutter.minSdkVersion // Using 23 directly as per your previous snippet
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties.getProperty("storeFile"))
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release") // Use the correctly named release config

            isMinifyEnabled = true // Kotlin DSL uses 'isMinifyEnabled'
            isShrinkResources = true // Kotlin DSL uses 'isShrinkResources'
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            // Ensure debug builds are not minified/shrunk for easier debugging
            isMinifyEnabled = false
            isShrinkResources = false
            // You might have a debug signing config here if needed, often defaults to debug.keystore
            // signingConfig = signingConfigs.debug // Example
        }
    }
}



flutter {
    source = "../.."
}
