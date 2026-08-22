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

// Some older plugin dependencies (e.g. isar_flutter_libs 3.1.0+1) don't declare
// an Android Gradle Plugin "namespace" and are compiled against an old SDK level,
// which newer AGP versions/transitive androidx deps require. Patch it in here so
// the build doesn't depend on editing files in the pub cache.
// Must be registered before evaluationDependsOn(":app") below, which forces
// early evaluation of :app and would otherwise make afterEvaluate too late.
subprojects {
    afterEvaluate {
        val androidExt = project.extensions.findByName("android") ?: return@afterEvaluate
        androidExt.withGroovyBuilder {
            if (getProperty("namespace") == null) {
                setProperty(
                    "namespace",
                    "dev.flutter.plugins.generated.${project.name.replace(Regex("[^A-Za-z0-9]"), "_")}",
                )
            }
            val currentCompileSdk = getProperty("compileSdkVersion")
            if (currentCompileSdk is Int && currentCompileSdk < 36) {
                setProperty("compileSdkVersion", 36)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
