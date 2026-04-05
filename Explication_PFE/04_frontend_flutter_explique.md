# 04 - Frontend Flutter Explique

## 1. Role du front Flutter

Le dossier `front-end/` contient l'application mobile principale du projet. C'est l'interface utilisateur destinee aux touristes, contributors et professionnels.

Le front Flutter consomme directement l'API du backend.

## 2. Point d'entree de l'application

Le point d'entree est `front-end/lib/main.dart`.

Au lancement, l'application :

- initialise Flutter
- tente d'initialiser Firebase
- initialise le stockage local
- initialise les notifications
- resout un eventuel deep link initial
- cree l'application avec son router et ses providers
- active Sentry si un DSN est fourni

Ce demarrage montre un front assez complet, avec :

- persistance locale
- notifications
- deep links
- monitoring

## 3. Gestion d'etat

Le front utilise `Provider`.

Dans `main.dart`, on voit notamment :

- `AuthProvider`
- `MapProvider`
- `SitesProvider`

Le role de ces providers est de centraliser certaines donnees et comportements pour que plusieurs ecrans puissent les reutiliser.

## 4. Navigation

La navigation repose sur `GoRouter` via `front-end/lib/core/router/app_router.dart`.

Le router gere :

- les ecrans publics
- les ecrans proteges
- la redirection selon l'etat de connexion
- les restrictions liees au role

Exemples de routes :

- `/welcome`
- `/login`
- `/register`
- `/home`
- `/map`
- `/sites`
- `/sites/:id`
- `/checkin/:id`
- `/review/:id`
- `/profile`
- `/leaderboard`
- `/professional/...`

Le code montre aussi que certaines routes sont reservees a des roles precis, en particulier pour l'espace professionnel.

## 5. Grandes fonctionnalites du mobile

### Authentification

L'application gere :

- login classique
- inscription
- logout
- Google Sign-In

Les fichiers lies a ce domaine sont surtout dans :

- `features/auth/data/`
- `features/auth/domain/`
- `features/auth/presentation/`

### Consultation des sites

Le mobile peut :

- lister les sites
- afficher leur detail
- voir des photos
- consulter les avis

Les fichiers lies a ce domaine sont surtout dans :

- `features/sites/presentation/`
- `core/network/api_service_sites.dart`

### Carte

Une partie cartographique est presente via :

- `flutter_map`
- `map_screen.dart`

Cette fonctionnalite est logique dans une application touristique geolocalisee.

### Check-in GPS

Le projet integre une fonctionnalite forte : le check-in sur un site avec des donnees de localisation.

Fichiers importants :

- `checkin_screen.dart`
- `checkin_detail_screen.dart`
- `api_service_checkins.dart`

### Avis

L'utilisateur peut :

- publier un avis
- consulter ses avis
- modifier ou supprimer ses avis

Fichiers importants :

- `add_review_screen.dart`
- `my_reviews_screen.dart`
- `api_service_reviews.dart`

### Profil, progression et gamification

Le profil utilisateur affiche des informations comme :

- statistiques
- badges
- leaderboard
- historique
- demande contributor

Le projet va donc au-dela d'un simple compte utilisateur.

### Espace professionnel

Le front prevoit un espace professionnel avec :

- hub professionnel
- liste des sites du professionnel
- creation de site
- revendication d'un site
- detail d'un site professionnel

Cela montre que le mobile couvre deja plusieurs parcours metiers.

## 6. Couche reseau

Le client HTTP principal est `ApiService` dans `front-end/lib/core/network/api_service.dart`.

Son role :

- stocker l'URL de base
- envoyer les requetes HTTP
- gerer les tokens
- tenter un refresh de session en cas de `401`
- gerer des URLs alternatives pour Android

Point tres interessant :

Le code prevoit des cas differents pour Android :

- emulateur Android : `10.0.2.2`
- debug USB / appareil physique : `127.0.0.1`

Cette logique est tres utile en demonstration sur telephone reel.

## 7. Stockage local

Le front utilise des mecanismes de stockage pour :

- conserver le token
- memoriser certaines preferences
- stocker des informations techniques comme l'URL API choisie

Cela rend l'application plus robuste entre deux ouvertures.

## 8. Fonctionnalites avancees visibles

Le code montre plusieurs aspects interessants pour un PFE :

### Deep links

Le service `AppDeepLinkService` montre que l'app peut repondre a des liens entrants.

### Notifications

`NotificationService` est initialise des le lancement.

### Biometrie

Le code de `main.dart` montre une protection biometrique possible a la reprise de l'application si l'utilisateur l'a activee.

### Synchronisation offline

Des services comme :

- `pending_checkin_service.dart`
- `pending_review_service.dart`
- `pending_sync_service.dart`

montrent une preparation a la reprise et a la synchronisation differeree.

## 9. Internationalisation

Le mobile supporte plusieurs langues :

- francais
- arabe
- anglais

On le voit avec :

- `app_fr.arb`
- `app_ar.arb`
- `app_en.arb`

Pour un projet touristique, ce choix est tres coherent.

## 10. Themes et presentation

Le front dispose d'une structure de theme avec :

- `app_theme.dart`
- `app_colors.dart`
- `app_text_styles.dart`
- `spacing_tokens.dart`

Cela montre une volonte de design system, meme si le projet reste avant tout un PFE fonctionnel.

## 11. Tests Flutter

Le projet contient deja plusieurs tests dans `front-end/test/`, par exemple sur :

- le router
- l'ecran de detail site
- l'ecran de check-in
- le leaderboard

## 12. Comment expliquer le front Flutter en soutenance

Une bonne formulation est :

- le mobile est le client principal de la plateforme
- il consomme l'API backend via `Dio`
- il structure les parcours par fonctionnalite
- il gere l'authentification, la geolocalisation, les avis et le profil
- il inclut des elements plus avances comme Firebase, Google Sign-In, offline sync, notifications et biometrie

## 13. Points forts du front

- application reelle et non simple prototype statique
- structure modulaire
- support multi-role
- prise en charge de la geolocalisation
- support multilingue
- compatibilite Android physique et emulateur

## 14. Points de vigilance

- les demos dependent du backend local
- certaines integrations externes doivent etre bien configurees
- la publication store n'est pas encore finalisee

Ces points peuvent etre presentes comme des etapes normales entre une version PFE fonctionnelle et une version produit industrialisee.
