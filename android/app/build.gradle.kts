import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") // Already included, no changes needed
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: android/key.properties (gitignored) points at the real
// upload keystore in android/keystore/. Falls back to debug signing only
// if key.properties is missing, so `flutter run --release` still works on
// a machine that hasn't been given the keystore.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.ebongsume.gostudy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    
    compileOptions {
        // Flag to enable support for the new language APIs
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
    
    defaultConfig {
        // TODO: Specify your own unique Application ID[](https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ebongsume.gostudy"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        multiDexEnabled = true
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
    // Size-variant comparison (temporary, edited between test builds — see
    // conversation with the size-reduction work): guarantees stripping
    // regardless of whether a lib came from Flutter's own output or a
    // plugin AAR, unlike ndk.abiFilters which Flutter's Gradle plugin
    // silently overrides.
    packaging {
        jniLibs {
            excludes += setOf(
                "lib/x86_64/**",
                "lib/armeabi-v7a/**",
                // MediaPipe vision/image-generation tasks — flutter_gemma is
                // used here for text-only chat (see GEMMA_MIGRATION_TODO.md),
                // these appear unreachable. Verify on-device before trusting.
                "**/libmediapipe_tasks_vision_jni.so",
                "**/libmediapipe_tasks_vision_image_generator_jni.so",
                "**/libimagegenerator_gpu.so",
                // Qualcomm Hexagon NPU (QNN) delegate — hardware acceleration
                // for specific Snapdragon chip generations. Removing this is
                // a real trade-off, not dead-code cleanup: inference should
                // still work by falling back to CPU/GPU, but will be slower
                // on Snapdragon devices that would otherwise use the NPU.
                "**/libQnnHtp*.so",
                "**/libQnnSystem.so",
                "**/libLiteRtDispatch_Qualcomm.so",
            )
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

dependencies {
    // Add the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.5.1")) // Use the latest version

    // Add Firebase dependencies for the products you want to use
    // Examples (uncomment or add the ones you need):
    // implementation("com.google.firebase:firebase-analytics")
    // implementation("com.google.firebase:firebase-auth")
    // implementation("com.google.firebase:firebase-firestore")
    // See https://firebase.google.com/docs/android/setup#available-libraries for more
    
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}

flutter {
    source = "../.."
}
