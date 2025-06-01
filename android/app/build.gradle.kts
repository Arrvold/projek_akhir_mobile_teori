// Tambahkan import ini di bagian paling atas file
import java.util.Properties
import org.gradle.api.Project // Biasanya sudah implisit, tapi bisa ditambahkan untuk kejelasan

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Fungsi untuk mendapatkan nilai dari local.properties atau default
fun getLocalProperty(key: String, project: Project, defaultValue: String = ""): String {
    val propertiesFile = project.rootProject.file("local.properties")
    if (propertiesFile.exists()) {
        val properties = Properties()
        propertiesFile.inputStream().use { input ->
            properties.load(input)
        }
        return properties.getProperty(key, defaultValue)
    }
    return System.getenv(key) ?: defaultValue
}


android {
    namespace = "com.example.projek_akhir_2" // Pastikan ini sesuai

    // Menggunakan fungsi getLocalProperty untuk membaca konfigurasi Flutter
    // Flutter menulis nilai-nilai ini ke local.properties
    compileSdk = 35 
    ndkVersion = "27.0.12077973" // Ini bisa Anda biarkan atau hapus jika tidak yakin memerlukannya

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.projek_akhir_2" // Pastikan ID aplikasi unik jika akan rilis
        minSdk = getLocalProperty("flutter.minSdkVersion", project, "21").toIntOrNull() ?: 21
        targetSdk = getLocalProperty("flutter.targetSdkVersion", project, "34").toIntOrNull() ?: 34
        versionCode = getLocalProperty("flutter.versionCode", project, "1").toIntOrNull() ?: 1
        versionName = getLocalProperty("flutter.versionName", project, "1.0")
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
    implementation(platform("org.jetbrains.kotlin:kotlin-bom:1.8.22")) // Atau versi Kotlin BOM yang sesuai
    // implementation(kotlin("stdlib-jdk8")) // Atau yang relevan

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}