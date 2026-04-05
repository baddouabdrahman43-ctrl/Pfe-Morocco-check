# MoroccoCheck Frontend

Application Flutter du projet MoroccoCheck.

Elle couvre le parcours utilisateur principal:

- authentification
- authentification Google mobile et web
- consultation des sites
- detail d un site
- check-in GPS
- publication d avis
- profil, stats, badges et leaderboard
- demande de passage `TOURIST -> CONTRIBUTOR`
- espace professionnel de base

## Prerequis

- Flutter stable
- Dart compatible avec le SDK du projet
- backend local demarre sur le port `5001`

## SDK

Le SDK declare est dans [pubspec.yaml](/C:/Users/User/App_Touriste/front-end/pubspec.yaml).

Avant de travailler sur le front:

```bash
cd front-end
flutter pub get
flutter analyze
```

## URL Backend

La resolution des URLs est centralisee dans:

- [app_constants.dart](/C:/Users/User/App_Touriste/front-end/lib/core/constants/app_constants.dart)

Valeurs par defaut:

- web / desktop: `http://127.0.0.1:5001/api`
- emulateur Android: `http://10.0.2.2:5001/api`

## Demarrage

```bash
cd front-end
flutter pub get
flutter run --flavor staging --dart-define=APP_ENV=development
```

## Environnements Et Flavors

Le mobile utilise maintenant les flavors Android:

- `staging`
- `production`

Template de variables:

- [front-end/.env.example](/C:/Users/User/App_Touriste/front-end/.env.example)

Reference globale:

- [ENVIRONMENTS.md](/C:/Users/User/App_Touriste/ENVIRONMENTS.md)

### Google Sign-In Mobile

Le login Google du front mobile utilise des `dart-define`:

```bash
flutter run \
  --flavor staging \
  --dart-define=APP_ENV=development \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=your-web-client-id.apps.googleusercontent.com \
  --dart-define=GOOGLE_IOS_CLIENT_ID=your-ios-client-id.apps.googleusercontent.com
```

Notes:

- Android: `GOOGLE_SERVER_CLIENT_ID` est requis pour recuperer le `idToken` envoye au backend
- iOS: `GOOGLE_SERVER_CLIENT_ID` et `GOOGLE_IOS_CLIENT_ID` sont requis
- le backend doit aussi accepter le client via `GOOGLE_CLIENT_IDS`

Configuration detaillee du projet:

- [GOOGLE_CLOUD_SETUP_MOBILE.md](/C:/Users/User/App_Touriste/GOOGLE_CLOUD_SETUP_MOBILE.md)

### Google Sign-In Web

Le bouton Google s affiche sur le web quand la configuration Firebase web et
le client Google web sont fournis:

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://127.0.0.1:5001 \
  --dart-define=FIREBASE_API_KEY=your-firebase-api-key \
  --dart-define=FIREBASE_PROJECT_ID=your-firebase-project-id \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=your-firebase-messaging-sender-id \
  --dart-define=FIREBASE_WEB_APP_ID=your-firebase-web-app-id \
  --dart-define=FIREBASE_WEB_AUTH_DOMAIN=your-project.firebaseapp.com \
  --dart-define=FIREBASE_STORAGE_BUCKET=your-project.firebasestorage.app \
  --dart-define=GOOGLE_WEB_CLIENT_ID=your-google-web-client-id.apps.googleusercontent.com
```

Notes:

- le bouton Google reste masque tant que la configuration Firebase web n est pas complete
- le backend doit continuer a valider les jetons Firebase Google sur `/api/auth/google`

### Chrome / Web

Sur cette machine, le lancement web le plus fiable est:

```bash
flutter run -d chrome --web-port 3001 --no-web-resources-cdn
```

Script equivalent:

```powershell
.\start-web-local.ps1
```

Depuis la racine, il existe aussi:

```powershell
.\start-app.ps1
```

## Flux Supportes

- inscription
- connexion
- auto-login
- logout
- consultation du profil
- mise a jour du profil
- affichage des stats
- affichage des badges
- affichage du leaderboard
- liste des sites
- detail d un site
- avis d un site
- photos d un site
- creation d un check-in
- creation d un avis
- affichage du statut contributor
- envoi d une demande contributor

## Contrat API Attendu

### Succes

```json
{
  "success": true,
  "data": {},
  "message": "..."
}
```

### Pagination

```json
{
  "success": true,
  "data": [],
  "meta": {
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 3
    }
  }
}
```

### Erreur

```json
{
  "success": false,
  "message": "..."
}
```

## Fichiers Cles

- [api_service.dart](/C:/Users/User/App_Touriste/front-end/lib/core/network/api_service.dart)
- [app_constants.dart](/C:/Users/User/App_Touriste/front-end/lib/core/constants/app_constants.dart)
- [auth_provider.dart](/C:/Users/User/App_Touriste/front-end/lib/features/auth/presentation/auth_provider.dart)
- [sites_provider.dart](/C:/Users/User/App_Touriste/front-end/lib/features/sites/presentation/sites_provider.dart)
- [site_detail_screen.dart](/C:/Users/User/App_Touriste/front-end/lib/features/sites/presentation/site_detail_screen.dart)
- [checkin_screen.dart](/C:/Users/User/App_Touriste/front-end/lib/features/sites/presentation/checkin_screen.dart)
- [profile_screen.dart](/C:/Users/User/App_Touriste/front-end/lib/features/profile/presentation/profile_screen.dart)

## Verification Recommandee

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --flavor staging --dart-define=APP_ENV=staging
```

Puis verifier manuellement:

1. inscription
2. connexion
3. liste des sites
4. detail d un site
5. check-in
6. avis
7. profil
8. demande contributor

## Limites Actuelles

- la publication mobile store n est pas encore preparee
- certains tests Flutter restent a completer
- les environnements `staging/prod` doivent encore etre formalises
