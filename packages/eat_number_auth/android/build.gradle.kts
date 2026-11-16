group = "you.v50to.eat.number_auth"
version = "1.0"

plugins {
    id("com.android.library")
}

// 号码认证 SDK 没有公开的 Maven 仓库, aar 放在本目录的 maven/ 下 (由 tool/number_auth_sdk.py 生成).
// 库模块不能直接依赖本地 aar 文件, 所以按 Maven 仓库的目录结构放, 并把它登记到所有工程, App 模块才解析得到.
val sdkRepository = uri("$projectDir/maven")
rootProject.allprojects {
    repositories {
        maven {
            url = sdkRepository
            content { includeGroup("local.aliyun.pnvs") }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

android {
    namespace = "you.v50to.eat.number_auth"
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        minSdk = 26
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    // 三个 aar 缺一不可, 版本跟随 SDK 压缩包, 升级时用 tool/number_auth_sdk.py 重新安装并同步改这里.
    // 混淆规则随 aar 自带.
    implementation("local.aliyun.pnvs:auth-number-product:2.14.25")
    implementation("local.aliyun.pnvs:logger:2.2.2")
    implementation("local.aliyun.pnvs:main:2.2.3")
    // 授权页的主题继承自 Theme.AppCompat.
    implementation("androidx.appcompat:appcompat:1.7.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
}
