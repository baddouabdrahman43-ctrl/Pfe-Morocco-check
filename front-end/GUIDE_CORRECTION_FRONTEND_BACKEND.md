# Guide de correction du frontend pour compatibilité backend

Ce guide sert de feuille de route pour aligner le frontend Flutter avec le backend Node/Express déjà présent dans `back-end/`.

Objectif:
- faire communiquer l'application Flutter avec les endpoints réels;
- supprimer les mocks qui cassent les parcours métier;
- stabiliser les payloads, réponses, modèles et écrans;
- obtenir un frontend compatible avec l'API actuelle.

---

## 1. Source de vérité backend

Le frontend doit considérer le backend actuel comme contrat de référence:

- Base URL API:
  - Android emulator: `http://10.0.2.2:5001/api`
  - Web / desktop local: `http://127.0.0.1:5001/api`
- Format succès:
  - `{ success: true, data: ..., message?: string }`
- Format erreur:
  - `{ success: false, message: string, code?: string, details?: any }`
- Auth:
  - `POST /api/auth/register`
  - `POST /api/auth/login`
  - `GET /api/auth/profile`
  - `PUT /api/auth/profile`
  - `POST /api/auth/logout`
- Sites:
  - `GET /api/sites`
  - `GET /api/sites/:id`
  - `GET /api/sites/:id/reviews`
  - `GET /api/sites/:id/photos`
- Check-ins:
  - `POST /api/checkins`
- Reviews:
  - `POST /api/reviews`
  - `GET /api/reviews`
  - `GET /api/reviews/:id`
- Utilisateur:
  - `GET /api/users/me`
  - `GET /api/users/me/badges`
  - `GET /api/users/me/stats`
  - `GET /api/badges`
  - `GET /api/leaderboard`

Important:
- le backend lit l'utilisateur depuis le JWT;
- `user_id` ne doit pas etre envoye dans les payloads proteges;
- plusieurs champs backend sont en `snake_case`.

---

## 2. Etat actuel

### Deja corrigé ou bien engagé

- [lib/core/constants/app_constants.dart](./lib/core/constants/app_constants.dart)
  - base URL locale alignee sur le backend.
- [lib/features/auth/data/auth_remote_datasource.dart](./lib/features/auth/data/auth_remote_datasource.dart)
  - auth branchee sur `/api/auth/*`.
- [lib/shared/models/user.dart](./lib/shared/models/user.dart)
  - mapping `first_name`, `last_name`, `rank`, `points`, `level`, `checkins_count`, `reviews_count`.
- [lib/core/network/api_service.dart](./lib/core/network/api_service.dart)
  - parsing API centralise et premiers appels backend reels.
- [lib/features/sites/presentation/sites_provider.dart](./lib/features/sites/presentation/sites_provider.dart)
  - la liste des sites peut venir de `GET /api/sites`.
- [lib/features/profile/presentation/profile_screen.dart](./lib/features/profile/presentation/profile_screen.dart)
  - le profil peut afficher les vraies donnees utilisateur.
- [lib/features/sites/presentation/checkin_screen.dart](./lib/features/sites/presentation/checkin_screen.dart)
  - payload mieux aligne avec le backend.
- [lib/features/sites/presentation/add_review_screen.dart](./lib/features/sites/presentation/add_review_screen.dart)
  - payload review aligne sur `content` au lieu de `comment`.

### Encore incompatibles ou incomplets

- [lib/features/map/presentation/map_screen.dart](./lib/features/map/presentation/map_screen.dart)
  - utilise toujours une liste mock.
- [lib/features/sites/presentation/site_detail_screen.dart](./lib/features/sites/presentation/site_detail_screen.dart)
  - detail, reviews et photos reposent encore en partie sur l'etat local et des contenus mock.
- [lib/features/sites/presentation/reviews_list.dart](./lib/features/sites/presentation/reviews_list.dart)
  - genere des avis fictifs.
- [lib/shared/models/tourist_site.dart](./lib/shared/models/tourist_site.dart)
  - modele parallele aux `Site` reels; duplication a reduire.
- [lib/features/sites/presentation/add_review_screen.dart](./lib/features/sites/presentation/add_review_screen.dart)
  - l'UI propose encore une photo, mais le backend n'a pas encore de route d'upload review utilisable.
- [pubspec.yaml](./pubspec.yaml)
  - SDK exige `^3.10.8`, alors que l'environnement local actuel est en `Dart 3.10.7`.

---

## 3. Regles de compatibilité à respecter

### 3.1 Auth

Payload `register`:

```json
{
  "first_name": "Ahmed",
  "last_name": "Benali",
  "email": "ahmed@example.com",
  "password": "Password123!"
}
```

Payload `login`:

```json
{
  "email": "ahmed@example.com",
  "password": "Password123!"
}
```

Réponse à parser:

```json
{
  "success": true,
  "data": {
    "access_token": "...",
    "refresh_token": "...",
    "token": "...",
    "user": {
      "id": 1,
      "first_name": "Ahmed",
      "last_name": "Benali",
      "email": "ahmed@example.com",
      "role": "TOURIST",
      "status": "ACTIVE",
      "points": 0,
      "level": 1,
      "rank": "BRONZE"
    }
  }
}
```

Règles:
- stocker `access_token`;
- stocker `refresh_token` pour futur refresh;
- ne pas construire le nom utilisateur avec un champ backend inexistant `name`;
- utiliser `/api/auth/profile` comme source principale du profil connecté.

### 3.2 Sites

Réponse `GET /api/sites`:

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Rick's Café",
      "description": "...",
      "category_name": "Restaurant",
      "cover_photo": null,
      "latitude": "33.59560000",
      "longitude": "-7.61850000",
      "average_rating": "4.50",
      "freshness_score": 0,
      "address": "...",
      "city": "Casablanca",
      "region": "Casablanca-Settat"
    }
  ],
  "meta": {
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 3
    }
  }
}
```

Règles:
- parser les nombres backend même s'ils arrivent comme chaînes;
- utiliser `category_name` au lieu d'un champ frontend `category` pur;
- prévoir `cover_photo == null`;
- éviter de dupliquer `Site` et `TouristSite` si un seul modèle suffit.

### 3.3 Check-in

Payload attendu:

```json
{
  "site_id": 1,
  "status": "OPEN",
  "comment": "Site ouvert",
  "latitude": 33.5956,
  "longitude": -7.6185,
  "accuracy": 20,
  "has_photo": false
}
```

Règles:
- ne pas envoyer `user_id`;
- utiliser les statuts backend en majuscules:
  - `OPEN`
  - `CLOSED`
  - `UNDER_CONSTRUCTION`
  - `CLOSED_TEMPORARILY`
  - `CLOSED_PERMANENTLY`
  - `RENOVATING`
  - `RELOCATED`
  - `NO_CHANGE`
- anticiper les erreurs `403`, `409`, `400`.

### 3.4 Review

Payload attendu:

```json
{
  "site_id": 1,
  "rating": 5,
  "title": "Tres belle visite",
  "content": "Avis detaille d'au moins 20 caracteres"
}
```

Règles:
- ne pas envoyer `user_id`;
- utiliser `content`, pas `comment`;
- respecter la longueur minimale backend;
- tant que l'upload media n'existe pas côté serveur, ne pas appeler de route `POST /reviews/photo`.

---

## 4. Ordre recommandé des corrections

### Priorité 1

Aligner les parcours critiques:

1. auth;
2. splash / auto-login;
3. liste des sites;
4. detail site;
5. check-in;
6. review.

### Priorité 2

Supprimer les données fictives visibles:

1. carte;
2. avis mock;
3. photos mock;
4. profil statique;
5. compteurs hardcodés.

### Priorité 3

Finaliser l'expérience:

1. badges;
2. stats utilisateur;
3. leaderboard;
4. gestion propre des erreurs réseau;
5. refresh token;
6. désactivation conditionnelle des features backend non prêtes.

---

## 5. Plan de correction par fichier

### 5.1 Réseau et modèles

- [lib/core/network/api_service.dart](./lib/core/network/api_service.dart)
  - centraliser tous les appels backend;
  - ajouter `getSiteById`, `getSiteReviews`, `getSitePhotos`, `getMyStats`, `getMyBadges`;
  - homogénéiser le parsing `{ success, data, meta }`.
- [lib/shared/models/user.dart](./lib/shared/models/user.dart)
  - conserver le mapping backend complet;
  - éviter les noms camelCase-only si le backend renvoie du snake_case.
- [lib/features/sites/presentation/sites/site.dart](./lib/features/sites/presentation/sites/site.dart)
  - garder ce modèle comme source principale pour les sites;
  - migrer progressivement les écrans encore basés sur `TouristSite`.
- [lib/shared/models/tourist_site.dart](./lib/shared/models/tourist_site.dart)
  - soit l'aligner sur le backend;
  - soit le supprimer après migration vers `Site`.

### 5.2 Auth et session

- [lib/features/auth/data/auth_remote_datasource.dart](./lib/features/auth/data/auth_remote_datasource.dart)
  - conserver l'usage de `/auth/login`, `/auth/register`, `/auth/profile`, `/auth/logout`.
- [lib/features/auth/data/auth_repository_impl.dart](./lib/features/auth/data/auth_repository_impl.dart)
  - ajouter plus tard la gestion du refresh token si besoin.
- [lib/features/auth/presentation/auth_provider.dart](./lib/features/auth/presentation/auth_provider.dart)
  - garder `autoLogin()` comme point d'entrée;
  - ajouter un rafraîchissement silencieux si le backend expose un flux refresh stable.
- [lib/splash/splash_screen.dart](./lib/splash/splash_screen.dart)
  - garder le splash comme bootstrap réel.

### 5.3 Sites

- [lib/features/sites/presentation/sites_provider.dart](./lib/features/sites/presentation/sites_provider.dart)
  - garder la source backend pour la liste;
  - ajouter pagination et filtres backend plus tard.
- [lib/features/sites/presentation/sites_list_screen.dart](./lib/features/sites/presentation/sites_list_screen.dart)
  - vérifier les libellés d'erreur/retry;
  - exploiter ensuite les filtres `city`, `region`, `category_id`, `min_rating`.
- [lib/features/sites/presentation/site_detail_screen.dart](./lib/features/sites/presentation/site_detail_screen.dart)
  - remplacer les sections mock par:
    - `GET /api/sites/:id`
    - `GET /api/sites/:id/reviews`
    - `GET /api/sites/:id/photos`
  - afficher `address`, `city`, `region`, `average_rating`, `freshness_score`;
  - ne pas supposer que les photos existent.

### 5.4 Carte

- [lib/features/map/presentation/map_screen.dart](./lib/features/map/presentation/map_screen.dart)
  - remplacer `_loadTouristSites()` par les sites venant du provider ou d'un service partagé;
  - réutiliser le modèle `Site`;
  - pointer vers `/sites/:id` avec les vrais ids backend;
  - ne plus hardcoder Agadir si les données viennent de tout le Maroc.

### 5.5 Reviews

- [lib/features/sites/presentation/add_review_screen.dart](./lib/features/sites/presentation/add_review_screen.dart)
  - garder le payload backend-compatible;
  - si l'upload n'est pas implémenté côté serveur:
    - masquer le bouton photo;
    - ou laisser l'UI visible avec mention "bientôt disponible".
- [lib/features/sites/presentation/reviews_list.dart](./lib/features/sites/presentation/reviews_list.dart)
  - supprimer `_generateMockReviews()`;
  - charger `GET /api/sites/:id/reviews`;
  - mapper `overall_rating`, `content`, `created_at`, `first_name`, `last_name`.
- [lib/features/sites/presentation/models/review.dart](./lib/features/sites/presentation/models/review.dart)
  - l'aligner sur le backend:
    - `overall_rating`
    - `content`
    - `created_at`
    - `first_name`
    - `last_name`
    - `profile_picture`

### 5.6 Profil

- [lib/features/profile/presentation/profile_screen.dart](./lib/features/profile/presentation/profile_screen.dart)
  - garder les données réelles du backend;
  - enrichir ensuite avec `/api/users/me/stats` et `/api/users/me/badges`.
- [lib/features/auth/data/auth_remote_datasource.dart](./lib/features/auth/data/auth_remote_datasource.dart)
  - pour le profil simple, `/api/auth/profile` suffit;
  - pour des écrans plus riches, compléter avec `/api/users/me`.

---

## 6. Incompatibilités connues à traiter explicitement

### Upload photo review

Situation actuelle:
- le frontend peut proposer une photo;
- le backend ne fournit pas encore une route d'upload review prête à l'emploi.

Correction recommandée:
- ne pas appeler de route d'upload tant que le backend ne l'expose pas;
- afficher un message UX clair;
- réactiver la feature seulement après ajout backend.

### Flutter SDK local

Situation actuelle:
- [pubspec.yaml](./pubspec.yaml) demande `sdk: ^3.10.8`;
- l'environnement local observé est `Dart 3.10.7`.

Impact:
- `flutter pub get` échoue;
- `flutter analyze` échoue;
- `dart format` peut échouer indirectement.

Correction recommandée:
- mettre à jour Flutter/Dart local;
- ou abaisser temporairement la contrainte SDK si l'équipe valide cette décision.

### Duplications de modèles et écrans

Situation actuelle:
- `Site` et `TouristSite` coexistent;
- plusieurs écrans gardent des données mock locales.

Correction recommandée:
- choisir `Site` comme modèle principal pour l'API backend;
- migrer `MapScreen` et les widgets associés;
- supprimer ensuite la duplication.

---

## 7. Checklist de compatibilité frontend

### Contrat API

- [ ] Tous les appels utilisent `AppConstants.baseUrl`
- [ ] Aucun endpoint frontend n'appelle une route inexistante
- [ ] Tous les payloads protégés n'envoient pas `user_id`
- [ ] Les champs snake_case backend sont correctement mappés
- [ ] Les réponses `{ success, data, meta }` sont correctement parsées

### Auth

- [ ] Register fonctionne avec `first_name` et `last_name`
- [ ] Login stocke access token et refresh token
- [ ] Splash restaure correctement la session
- [ ] Profil se recharge depuis le backend
- [ ] Logout supprime le token local et ferme la session backend

### Sites

- [ ] La liste des sites ne dépend plus des mocks
- [ ] Le détail site vient du backend
- [ ] Les reviews viennent du backend
- [ ] Les photos viennent du backend ou sont masquées
- [ ] La carte affiche les vrais sites backend

### Check-in / review

- [ ] Le check-in envoie les statuts backend valides
- [ ] L'avis envoie `content`
- [ ] Les erreurs `409`, `403`, `401`, `400` sont bien affichées
- [ ] Les écrans se rafraîchissent après action réussie

### Qualité

- [ ] `flutter pub get` passe
- [ ] `flutter analyze` passe
- [ ] `flutter test` passe
- [ ] Le README frontend décrit le setup backend local

---

## 8. Ordre d'exécution conseillé

1. Corriger l'environnement Flutter local pour pouvoir analyser et tester.
2. Stabiliser le réseau et les modèles API.
3. Terminer l'intégration `sites -> detail -> reviews -> photos`.
4. Migrer la carte sur les données backend réelles.
5. Finaliser le profil enrichi (`/users/me`, badges, stats).
6. Documenter le workflow frontend local dans le README.

---

## 9. Résultat attendu

À la fin de ces corrections, le frontend devra:

- se connecter au backend local sans modifier le code à chaque test;
- charger les utilisateurs et les sites réels;
- exécuter les flux auth, check-in et review contre l'API;
- ne plus afficher de données fictives sur les écrans principaux;
- rester cohérent avec les contraintes métier du backend.
