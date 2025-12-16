allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Fix pour les espaces dans le chemin utilisateur - utiliser un buildDir relatif
// Le buildDir personnalisé cause des problèmes avec Flutter qui cherche l'APK au mauvais endroit
// On utilise maintenant le buildDir par défaut mais avec un chemin relatif
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
