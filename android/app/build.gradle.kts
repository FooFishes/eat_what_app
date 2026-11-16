import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// release 用 android/key.properties 指向的上传密钥签名. 文件不存在时回落到 debug 签名, 产物只能用于测试.
// 密钥和 key.properties 都不入库, CI 从 Secrets 还原.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "you.v50to.eat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "you.v50to.eat"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // sentry_flutter 要求 API 26 及以上.
        minSdk = maxOf(flutter.minSdkVersion, 26)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Flutter 插件把 abiFilters 固定成三种架构, 不看 --target-platform; 只有 libflutter.so 和 libapp.so 按它打.
        // 结果是 CI 只打 ARM 时, 百度地图、Sentry 等插件的 x86_64 库仍然进包, 而那个架构上没有 Flutter 引擎, 根本跑不起来.
        // 这里让 abiFilters 跟着 --target-platform 走. flutter run 和 flutter build 都会传这个属性.
        (findProperty("target-platform") as String?)?.let { platforms ->
            val abis = mapOf("android-arm" to "armeabi-v7a", "android-arm64" to "arm64-v8a", "android-x64" to "x86_64")
            ndk.abiFilters.clear()
            ndk.abiFilters += platforms.split(",").map { abis.getValue(it) }
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
