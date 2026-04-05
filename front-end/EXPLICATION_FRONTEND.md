# Explication Detaillee Du Frontend MoroccoCheck

## 1. Vue d ensemble

Le frontend de `MoroccoCheck` est une application `Flutter` orientee mobile, structuree par modules metier (`features`) avec une separation claire entre :

- la couche visuelle,
- la gestion d etat,
- la communication avec le backend,
- le stockage local,
- et les modeles de donnees.

Le frontend actuel est centre sur `Agadir`, autant dans les donnees que dans l experience utilisateur.

Les points d entree principaux sont :

- [main.dart](/c:/Users/User/App_Touriste/front-end/lib/main.dart)
- [app_router.dart](/c:/Users/User/App_Touriste/front-end/lib/core/router/app_router.dart)
- [api_service.dart](/c:/Users/User/App_Touriste/front-end/lib/core/network/api_service.dart)

## 2. Structure Generale

Le dossier [lib](/c:/Users/User/App_Touriste/front-end/lib) est organise ainsi :

- [core](/c:/Users/User/App_Touriste/front-end/lib/core) : fondations techniques
- [features](/c:/Users/User/App_Touriste/front-end/lib/features) : modules metier
- [shared](/c:/Users/User/App_Touriste/front-end/lib/shared) : modeles et widgets reutilisables
- [splash](/c:/Users/User/App_Touriste/front-end/lib/splash) : ecran de demarrage
- [debug](/c:/Users/User/App_Touriste/front-end/lib/debug) : outillage de debug

### 2.1 Core

Le dossier `core` contient les briques transverses :

- [app_router.dart](/c:/Users/User/App_Touriste/front-end/lib/core/router/app_router.dart) : navigation et guards
- [api_service.dart](/c:/Users/User/App_Touriste/front-end/lib/core/network/api_service.dart) : client HTTP central
- [storage_service.dart](/c:/Users/User/App_Touriste/front-end/lib/core/storage/storage_service.dart) : stockage local, tokens, preferences
- [app_theme.dart](/c:/Users/User/App_Touriste/front-end/lib/core/theme/app_theme.dart) : theme global
- [app_constants.dart](/c:/Users/User/App_Touriste/front-end/lib/core/constants/app_constants.dart) : constantes applicatives

### 2.2 Features

Le dossier `features` est decoupe par domaine fonctionnel :

- [auth](/c:/Users/User/App_Touriste/front-end/lib/features/auth) : connexion, inscription, session
- [sites](/c:/Users/User/App_Touriste/front-end/lib/features/sites) : liste, detail, avis, photos, check-in
- [map](/c:/Users/User/App_Touriste/front-end/lib/features/map) : carte interactive
- [profile](/c:/Users/User/App_Touriste/front-end/lib/features/profile) : profil, leaderboard, badges
- [professional](/c:/Users/User/App_Touriste/front-end/lib/features/professional) : gestion des etablissements professionnels
- [settings](/c:/Users/User/App_Touriste/front-end/lib/features/settings) : preferences locales
- [home](/c:/Users/User/App_Touriste/front-end/lib/features/home) : shell principal et navigation basse

## 3. Point D Entree De L Application

Le point d entree est [main.dart](/c:/Users/User/App_Touriste/front-end/lib/main.dart).

Il fait trois choses importantes :

1. initialise le stockage local avec `StorageService`
2. injecte les providers principaux
3. demarre `MaterialApp.router`

Les providers globaux branches au demarrage sont :

- `AuthProvider`
- `MapProvider`
- `SitesProvider`

Cela signifie que l etat de session, de carte et de catalogue de sites est disponible a l echelle globale de l application.

## 4. Routage Et Navigation

Le routage est centralise dans [app_router.dart](/c:/Users/User/App_Touriste/front-end/lib/core/router/app_router.dart) avec `GoRouter`.

### 4.1 Routes principales

- `/` : splash
- `/welcome`
- `/login`
- `/register`
- `/forgot-password`
- `/home`
- `/map`
- `/sites`
- `/sites/:id`
- `/checkin/:id`
- `/review/:id`
- `/profile`
- `/profile/edit`
- `/profile/badges`
- `/leaderboard`
- `/professional/sites`
- `/professional/sites/new`
- `/professional/sites/:id`
- `/professional/sites/:id/edit`

### 4.2 Guards de navigation

Le frontend applique une logique de protection avant meme d appeler le backend :

- un utilisateur non connecte ne peut pas entrer sur les routes protegees
- un utilisateur connecte ne retourne pas normalement vers `login` ou `register`
- les routes `professional` sont reservees au role `PROFESSIONAL`

Cela evite une partie des erreurs de navigation et rend l UX plus propre.

## 5. Theme Et Identite Visuelle

Le theme global est defini dans [app_theme.dart](/c:/Users/User/App_Touriste/front-end/lib/core/theme/app_theme.dart).

L orientation visuelle est la suivante :

- `Material 3`
- palette claire
- dominante bleue / verte
- composants arrondis
- app orientee lisibilite et confiance

Le but du design n est pas d etre experimental, mais d etre clair, moderne et rassurant pour un produit de verification terrain.

## 6. Configuration Applicative

Le fichier [app_constants.dart](/c:/Users/User/App_Touriste/front-end/lib/core/constants/app_constants.dart) centralise :

- l URL API
- les timeouts reseau
- la version
- l email de support
- le focus geographique sur `Agadir`

Exemples importants :

- `focusCity = 'Agadir'`
- `focusRegion = 'Souss-Massa'`
- `focusLatitude = 30.4278`
- `focusLongitude = -9.5981`

L URL API s adapte aussi selon la plateforme :

- web : `127.0.0.1`
- Android emulator : `10.0.2.2`
- override possible via `--dart-define API_BASE_URL=...`

## 7. Communication Avec Le Backend

Le client principal est [api_service.dart](/c:/Users/User/App_Touriste/front-end/lib/core/network/api_service.dart), base sur `Dio`.

### 7.1 Responsabilites de ApiService

- gerer toutes les requetes HTTP
- injecter automatiquement le token JWT
- gerer les erreurs reseau
- parser le format de reponse du backend
- rafraichir automatiquement le token si besoin

### 7.2 Refresh token

Le frontend implemente une vraie logique de session resiliente :

- si une requete retourne `401`
- le client tente `POST /auth/refresh`
- il met a jour le token d acces
- puis rejoue la requete initiale

Cette logique permet de garder l utilisateur connecte sans lui demander de se reconnecter trop souvent.

### 7.3 Endpoints utilises

Le frontend consomme notamment :

- `POST /auth/login`
- `POST /auth/register`
- `GET /auth/profile`
- `PUT /auth/profile`
- `POST /auth/refresh`
- `POST /auth/logout`
- `GET /sites`
- `GET /sites/:id`
- `GET /sites/:id/reviews`
- `GET /sites/:id/photos`
- `POST /checkins`
- `POST /reviews`
- `GET /users/me/stats`
- `GET /users/me/badges`
- `GET /badges`
- `GET /leaderboard`
- `GET /sites/mine`
- `GET /sites/mine/:id`
- `POST /sites`
- `PUT /sites/:id`

## 8. Stockage Local

Le stockage local est gere par [storage_service.dart](/c:/Users/User/App_Touriste/front-end/lib/core/storage/storage_service.dart).

### 8.1 Ce qui est stocke

- access token
- refresh token
- donnees utilisateur
- etat de connexion
- preferences locales

### 8.2 Technologies utilisees

- `flutter_secure_storage` pour les tokens
- `shared_preferences` pour les preferences et certaines donnees locales

### 8.3 Preferences locales

Le frontend memorise notamment :

- langue preferee
- notifications activees ou non
- localisation precise activee ou non
- affichage des infos techniques

## 9. Modele Utilisateur

Le modele principal est [user.dart](/c:/Users/User/App_Touriste/front-end/lib/shared/models/user.dart).

Il est aligne avec le backend et represente :

- identite : `firstName`, `lastName`, `email`
- profil : `phoneNumber`, `nationality`, `bio`, `profilePicture`
- role et statut
- progression : `points`, `level`, `rank`
- statistiques : `checkinsCount`, `reviewsCount`, `badgeCount`
- session : `token`, `refreshToken`

Ce modele sert de colonne vertebrale entre l API, l auth, le profil et les ecrans metier.

## 10. Processus Metier Cote Client

## 10.1 Authentification

L authentification est geree par :

- [auth_provider.dart](/c:/Users/User/App_Touriste/front-end/lib/features/auth/presentation/auth_provider.dart)
- [auth_repository_impl.dart](/c:/Users/User/App_Touriste/front-end/lib/features/auth/data/auth_repository_impl.dart)

Le provider orchestre :

- login
- register
- logout
- autoLogin
- refreshUser

Le repository gere :

- la communication serveur
- l enregistrement local du token
- la sauvegarde des donnees utilisateur
- le nettoyage de session

L ecran de demarrage [splash_screen.dart](/c:/Users/User/App_Touriste/front-end/lib/splash/splash_screen.dart) appelle `autoLogin`, ce qui cree un vrai flux de reprise de session.

## 10.2 Consultation des sites

La logique de liste est dans [sites_provider.dart](/c:/Users/User/App_Touriste/front-end/lib/features/sites/presentation/sites_provider.dart).

Le provider :

- charge les sites depuis le backend
- force le filtre `city=Agadir`
- gere la recherche locale
- gere le filtrage par categorie
- conserve les sites deja check-in localement

L ecran correspondant est [sites_list_screen.dart](/c:/Users/User/App_Touriste/front-end/lib/features/sites/presentation/sites_list_screen.dart).

## 10.3 Detail d un lieu

La fiche d un site est geree par [site_detail_screen.dart](/c:/Users/User/App_Touriste/front-end/lib/features/sites/presentation/site_detail_screen.dart).

Elle recharge :

- la fiche complete du lieu
- les photos
- les avis

Elle contient aussi les actions principales :

- `Check-in`
- `Ajouter un avis`

Si l utilisateur n est pas connecte, ces actions sont bloquees proprement cote UI.

## 10.4 Check-in

Le parcours check-in est dans [checkin_screen.dart](/c:/Users/User/App_Touriste/front-end/lib/features/sites/presentation/checkin_screen.dart).

Processus metier :

1. recuperer le lieu
2. verifier la permission GPS
3. recuperer la position actuelle
4. calculer la distance au lieu
5. refuser si la distance est trop grande
6. envoyer le check-in au backend
7. rafraichir les donnees utilisateur

L ecran gere aussi les cas d erreur :

- session expiree
- deja check-in aujourd hui
- distance trop grande
- pas de connexion

## 10.5 Avis

Le flux d avis se compose de :

- [add_review_screen.dart](/c:/Users/User/App_Touriste/front-end/lib/features/sites/presentation/add_review_screen.dart)
- [reviews_list.dart](/c:/Users/User/App_Touriste/front-end/lib/features/sites/presentation/reviews_list.dart)

Le frontend sait :

- envoyer un avis texte
- charger les avis d un lieu
- gerer les erreurs metier backend

Le faux flux photo a ete retire en tant que fonctionnalite active, pour rester honnete avec l etat reel du backend.

## 10.6 Profil Et Gamification

Le profil est dans [profile_screen.dart](/c:/Users/User/App_Touriste/front-end/lib/features/profile/presentation/profile_screen.dart).

Le frontend y assemble plusieurs dimensions :

- identite utilisateur
- progression niveau / rang
- statistiques de contribution
- badges
- activite recente
- acces au leaderboard
- acces au catalogue des badges

Les ecrans lies sont :

- [edit_profile_screen.dart](/c:/Users/User/App_Touriste/front-end/lib/features/profile/presentation/edit_profile_screen.dart)
- [leaderboard_screen.dart](/c:/Users/User/App_Touriste/front-end/lib/features/profile/presentation/leaderboard_screen.dart)
- [badges_catalog_screen.dart](/c:/Users/User/App_Touriste/front-end/lib/features/profile/presentation/badges_catalog_screen.dart)

## 10.7 Parcours professionnel

Le role `PROFESSIONAL` a maintenant son propre espace.

Les ecrans principaux sont :

- [professional_sites_screen.dart](/c:/Users/User/App_Touriste/front-end/lib/features/professional/presentation/professional_sites_screen.dart)
- [create_site_screen.dart](/c:/Users/User/App_Touriste/front-end/lib/features/professional/presentation/create_site_screen.dart)
- [professional_site_detail_screen.dart](/c:/Users/User/App_Touriste/front-end/lib/features/professional/presentation/professional_site_detail_screen.dart)

Ce module permet :

- de voir ses etablissements
- de filtrer par statut
- d ajouter un lieu
- de modifier un lieu
- de consulter le detail proprietaire
- de voir les retours de moderation

## 11. Interfaces Graphiques Et UX

## 11.1 Shell principal

Le shell principal est [home_screen.dart](/c:/Users/User/App_Touriste/front-end/lib/features/home/presentation/home_screen.dart).

Il utilise un `IndexedStack` avec 4 onglets :

- Carte
- Sites
- Profil
- Reglages

Cette organisation est pertinente pour un usage mobile :

- la carte pour l exploration geographique
- la liste pour la navigation contenu
- le profil pour la progression et les actions personnelles
- les reglages pour les preferences

## 11.2 Carte

La carte est geree dans [map_screen.dart](/c:/Users/User/App_Touriste/front-end/lib/features/map/presentation/map_screen.dart).

Points UX importants :

- recentrage sur Agadir
- centrage sur l utilisateur
- marqueurs selon la fraicheur
- filtres visuels categorie / fraicheur
- resume dynamique en bas

La carte est donc plus qu un simple affichage: c est un espace d exploration et de tri visuel.

## 11.3 Liste des sites

La liste [sites_list_screen.dart](/c:/Users/User/App_Touriste/front-end/lib/features/sites/presentation/sites_list_screen.dart) a une UX de decouverte :

- carte hero d introduction
- recherche
- filtres categorie
- compteur de resultats
- pull-to-refresh

Elle est pensee pour un utilisateur qui cherche vite un lieu utile autour d Agadir.

## 11.4 Detail d un site

La fiche [site_detail_screen.dart](/c:/Users/User/App_Touriste/front-end/lib/features/sites/presentation/site_detail_screen.dart) est l une des pages les plus riches.

Elle contient :

- hero visuel
- chips de contexte
- cartes metriques
- boutons de contribution
- tabs `Info / Avis / Photos`

Cette page joue le role de fiche centrale produit.

## 11.5 Profil

Le profil a une UX mixte :

- identitaire
- communautaire
- ludique

L utilisateur y retrouve :

- son image et ses infos
- son rang
- sa progression
- ses badges
- son historique
- l acces a ses fonctions avancees

## 11.6 Reglages

L ecran [settings_screen.dart](/c:/Users/User/App_Touriste/front-end/lib/features/settings/presentation/settings_screen.dart) est devenu un vrai centre de preferences.

Il inclut :

- langue
- notifications
- precision de localisation
- infos techniques
- etat des permissions
- vie privee
- support
- reset des preferences

## 12. UI / UX : logique de conception

L UX actuelle cherche surtout a etre :

- claire
- rapide a comprendre
- utile sur le terrain
- honnete par rapport aux fonctions reelles du backend

Le frontend evite de promettre des fonctions non disponibles :

- les actions protegees sont bloquees pour les visiteurs
- le mot de passe oublie est informatif tant que le backend n existe pas
- l upload photo review n est pas presente comme une vraie fonction active

Cette coherence entre UI et backend est un vrai point de maturite.

## 13. Forces Du Frontend

- structure modulaire propre
- integration backend reelle
- refresh token fonctionnel
- guards de navigation en place
- parcours professionnel deja solide
- carte et liste des sites bien pensees
- profil enrichi et branche
- preferences locales bien gerees

## 14. Limites Actuelles

- pas encore de vrai flux `forgot password`
- pas encore d upload photo review actif
- identite visuelle encore plutot MVP que premium
- administration separee dans `admin-web`, donc absente de cette app Flutter, ce qui est normal

## 15. Conclusion

Le frontend actuel est deja un vrai produit applicatif, pas seulement un prototype d ecrans.

Il relie correctement :

- la session utilisateur,
- l exploration des lieux,
- la cartographie,
- la contribution terrain,
- la gamification,
- le parcours professionnel,
- et la personnalisation locale.

En resume, l application cote client est aujourd hui une base solide, modulaire et evolutive pour MoroccoCheck, avec une UX particulierement adaptee a un usage mobile terrain autour d Agadir.
