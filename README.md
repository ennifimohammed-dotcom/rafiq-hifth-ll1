# Quran Teacher Tracker

Application Flutter pour les professeurs de Coran : suivi de mémorisation, révision, présence et notes, avec partage de rapports en lecture seule pour les parents via lien / QR code.

## Stack
- Flutter (stable) + Dart null-safety
- Firebase Auth + Cloud Firestore + Firebase Storage
- Riverpod (state management)
- Clean Architecture (data / domain / presentation)
- Material 3 — thème vert islamique

## Architecture
```
lib/
  core/         # thème, router, constantes, utils
  data/         # modèles, datasources Firebase, repositories impl
  domain/       # entités, contrats de repositories, use cases
  presentation/ # providers Riverpod, screens, widgets
```

## Configuration Firebase
1. Créer un projet Firebase : https://console.firebase.google.com
2. Activer **Authentication → Email/Password**, **Firestore Database**, **Storage**
3. Installer la CLI FlutterFire :
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Cela génère `lib/firebase_options.dart` automatiquement (remplace le placeholder fourni).
4. Pour Android, place `google-services.json` dans `android/app/`.

## Lancer le projet
```
flutter pub get
flutter run
```

## Build APK
```
flutter build apk --release
```
APK généré dans `build/app/outputs/flutter-apk/app-release.apk`.

## Build App Bundle (Play Store)
```
flutter build appbundle --release
```

## Compte enseignant
Crée le compte enseignant manuellement dans Firebase Authentication, puis connecte-toi dans l'app. Les parents n'ont pas de compte — ils ouvrent simplement le lien de rapport partagé.

## Règles Firestore recommandées
Voir `firestore.rules` à la racine.
