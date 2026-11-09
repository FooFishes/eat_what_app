group = "you.v50to.eat.baidu_map"
version = "1.0"

plugins {
    id("com.android.library")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

android {
    namespace = "you.v50to.eat.baidu_map"
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        minSdk = 26
        consumerProguardFiles("consumer-rules.pro")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    // 只要地图, 不带定位和检索. 升级时同时检查 iOS 的 tool/baidu_ios_sdk.sh.
    implementation("com.baidu.lbsyun:BaiduMapSDK_Map:8.2.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
}
