plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.panopticon"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion = flutter.ndkVersion  // Commented out: NDK not required for debug builds (ObjectBox uses pre-built AARs)

    externalNativeBuild {
        cmake {
            // Path is relative to this build.gradle.kts file
            path = file("../../native/libllama_bridge/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.panopticon"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            // Target the two primary 64-bit Android ABIs.
            // arm64-v8a  → ARMv8 phones (Pixel, Samsung, OnePlus, etc.)
            // x86_64     → Android emulator on x86_64 hosts (CI / dev)
            abiFilters += listOf("arm64-v8a", "x86_64")
        }

        externalNativeBuild {
            cmake {
                // Pass compile-time flags to CMake.
                // Set LLAMA_REAL=1 once vendor/llama.cpp is present.
                arguments("-DLLAMA_REAL=0", "-DBUILD_TESTS=OFF", "-DANDROID=ON")
                cppFlags("-std=c++17", "-O3", "-fPIC")
            }
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
