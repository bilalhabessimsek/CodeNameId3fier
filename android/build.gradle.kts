import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import com.android.build.gradle.BaseExtension
import org.gradle.api.JavaVersion

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    if (project.state.executed) {
        configureNamespace(project)
    } else {
        project.afterEvaluate {
            configureNamespace(project)
        }
    }

    // Force all modules to use Java 17 and Kotlin 17
    project.afterEvaluate {
        if (project.extensions.findByName("android") != null) {
            val android = project.extensions.getByName("android")
            if (android is BaseExtension) {
                android.compileOptions.sourceCompatibility = JavaVersion.VERSION_17
                android.compileOptions.targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }

    tasks.withType<KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "17"
        }
    }
}

fun configureNamespace(project: Project) {
    val android = project.extensions.findByName("android") ?: return
    try {
        val getNamespace = android.javaClass.getMethod("getNamespace")
        val ns = getNamespace.invoke(android)
        if (ns == null) {
            val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
            setNamespace.invoke(android, project.group.toString())
        }
    } catch (e: Exception) {
       // ignore
    }
}
