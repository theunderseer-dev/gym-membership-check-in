plugins {
    id("com.android.application") version "8.7.2" apply false
    id("com.android.library") version "8.7.2" apply false
    id("org.jetbrains.kotlin.android") version "2.1.20" apply false
    id("org.jetbrains.kotlin.multiplatform") version "2.1.20" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.1.20" apply false
    id("com.google.devtools.ksp") version "2.1.20-1.0.32" apply false
    id("org.jlleitschuh.gradle.ktlint") version "12.2.0" apply false
    id("io.gitlab.arturbosch.detekt") version "1.23.8" apply false
    id("org.jetbrains.kotlinx.kover") version "0.9.1" apply false
}

subprojects {
    apply(plugin = "org.jlleitschuh.gradle.ktlint")
    apply(plugin = "io.gitlab.arturbosch.detekt")

    configure<org.jlleitschuh.gradle.ktlint.KtlintExtension> {
        android.set(true)
        ignoreFailures.set(false)
        filter {
            exclude("**/generated/**")
            exclude("**/build/**")
        }
    }

    configure<io.gitlab.arturbosch.detekt.extensions.DetektExtension> {
        buildUponDefaultConfig = true
        allRules = false
        config.setFrom(files("$rootDir/config/detekt/detekt.yml"))
        source.setFrom(
            files(
                "src/main/java",
                "src/main/kotlin",
                "src/commonMain/kotlin",
                "src/androidMain/kotlin",
                "src/iosMain/kotlin"
            )
        )
    }
}
