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
    // 地图和地点检索, 不带定位. 两个版本一起升级, 同时检查 iOS 的 tool/baidu_ios_sdk.sh.
    implementation("com.baidu.lbsyun:BaiduMapSDK_Map:8.2.0")
    implementation("com.baidu.lbsyun:BaiduMapSDK_Search:8.2.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
}
