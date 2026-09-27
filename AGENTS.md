# Instructions pour l'agent

## Gestion des versions Gradle / Kotlin / AGP / Flutter

- Avant de modifier `android/build.gradle.kts`, `android/settings.gradle.kts`, 
  `android/gradle/wrapper/gradle-wrapper.properties` ou tout fichier lié au build Android, 
  vérifie systématiquement la compatibilité entre :
  - la version de Flutter installée (`flutter --version`)
  - la version du plugin Kotlin (`org.jetbrains.kotlin.android`)
  - la version de l'Android Gradle Plugin (AGP)
  - la version de Gradle elle-même
  Ces versions sont interdépendantes : ne jamais en changer une seule sans vérifier les autres.

- Ne propose jamais `--android-skip-build-dependency-validation` ou un flag de contournement 
  comme solution : corrige la vraie version dans le fichier concerné.

- Après toute modification d'un fichier Gradle, exécute `.\gradlew.bat --stop` (dans le dossier `android`), puis `flutter clean && flutter pub get` puis un build de test (`flutter run` ou `flutter build apk --debug`) avant de considérer la tâche terminée. En cas d'échec de build, arrête systématiquement les daemons Gradle via `.\gradlew.bat --stop` avant de réessayer.

- En cas d'erreur de build liée à une version (Kotlin, AGP, Gradle, NDK), explique-moi 
  clairement quelle version est en cause et quelle version cible tu proposes, avant 
  d'appliquer le changement.

- Ne mets pas à jour Flutter, Gradle, Kotlin ou AGP vers une version majeure sans me le 
  signaler explicitement, car cela peut casser la compatibilité avec le reste du projet 
  (Firebase, plugins natifs, etc.).

- Les plugins Firebase (`cloud_functions`, `firebase_core`, `firebase_database`, etc.) 
  doivent rester à jour vers les versions les plus récentes compatibles avec le 
  "Built-in Kotlin" (BIK) de Flutter/AGP 9+. Si un warning mentionne KGP appliqué par 
  un plugin, propose une mise à jour de `pubspec.yaml` plutôt qu'un contournement.
