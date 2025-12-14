allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Fix pour les espaces dans le chemin utilisateur - utiliser un buildDir absolu sans espace
val customBuildDirPath = "C:/build/flutter-build"
val newBuildDir = rootProject.layout.projectDirectory.dir(customBuildDirPath)
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
