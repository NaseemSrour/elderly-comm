allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Some plugins (file_picker's flutter_plugin_android_lifecycle) require every
// Android module to compile against SDK 36, but Flutter's default compileSdk is
// still 34 here and each plugin subproject inherits that default. Force any
// Android subproject still below 36 up to 36. Reflection keeps this working
// across AGP DSL versions (the property is `compileSdk: Int?`).
fun Project.raiseCompileSdkTo36() {
    val android = extensions.findByName("android") ?: return
    try {
        val current =
            android.javaClass.getMethod("getCompileSdk").invoke(android) as? Int
        if (current == null || current < 36) {
            android.javaClass
                .getMethod("setCompileSdk", Integer::class.java)
                .invoke(android, 36)
        }
    } catch (_: NoSuchMethodException) {
        // Older DSL: fall back to the string-based API.
        android.javaClass
            .getMethod("compileSdkVersion", String::class.java)
            .invoke(android, "android-36")
    }
}

subprojects {
    project.evaluationDependsOn(":app")
    // `evaluationDependsOn(":app")` above evaluates :app eagerly, so it may
    // already be evaluated here — apply directly in that case, otherwise defer.
    if (state.executed) raiseCompileSdkTo36() else afterEvaluate { raiseCompileSdkTo36() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
