# Realisation et Implementation

---

## CHAPITRE 3 - Realisation et implementation

### 3.1 Environnement de developpement

#### Langages et frameworks

| Technologie | Version | Role dans le projet |
|-------------|---------|---------------------|
| JavaScript (Node.js) | v20.19.5 | Execution du backend Express et des scripts serveur |
| npm | 10.8.2 | Gestion des dependances backend et admin web |
| Express | 5.2.1 | Exposition de l'API REST |
| MySQL | 8.x | Persistance des donnees metier |
| mysql2 | 3.16.2 | Connectivite base de donnees cote Node.js |
| Joi | 18.0.2 | Validation des charges utiles HTTP |
| JSON Web Token | 9.0.3 | Authentification stateless via jetons signes |
| bcryptjs | 3.0.3 | Hachage des mots de passe |
| multer | 2.0.2 | Upload de fichiers medias |
| Helmet | 8.1.0 | Renforcement de la securite HTTP |
| Flutter | 3.38.7 | Application mobile et web grand public |
| Dart | 3.10.7 | Langage principal du client Flutter |
| Provider | 6.1.2 | Gestion d'etat cote Flutter |
| go_router | 14.2.7 | Routage declaratif Flutter |
| Dio | 5.4.2 | Appels HTTP cote Flutter |
| flutter_map | 8.2.2 | Affichage cartographique dans l'application Flutter |
| geolocator | 10.1.0 | Recuperation de la position GPS |
| google_sign_in | 7.2.0 | Connexion Google via federation cote client |
| firebase_core | 4.6.0 | Initialisation Firebase dans Flutter |
| firebase_auth | 6.3.0 | Authentification Firebase dans Flutter |
| React | 18.3.1 | Interface d'administration web |
| react-router-dom | 6.30.1 | Navigation SPA cote admin |
| Vite | 5.4.11 | Build et serveur de developpement admin |
| TypeScript | 5.9.3 | Typage de l'outillage front admin |
| Firebase Web SDK | 12.11.0 | Support Google Sign-In pour l'admin web |
| Sentry | 10.46.0 / 9.16.0 | Supervision des erreurs backend, admin web et Flutter |

#### Outils de developpement

| Outil | Version | Usage |
|-------|---------|-------|
| Git | 2.52.0.windows.1 | Controle de version du depot |
| GitHub Actions | [Information non disponible dans le code source - a completer manuellement] | Integration continue backend, Flutter et admin web |
| Visual Studio Code | [Information non disponible dans le code source - a completer manuellement] | Edition probable du code source |
| Mocha | 11.7.4 | Tests backend Node.js |
| Chai | 5.3.3 | Assertions backend |
| Supertest | 7.1.4 | Tests d'API Express |
| Vitest | 2.1.9 | Tests de l'interface admin web |
| Flutter Test | inclus avec Flutter 3.38.7 | Tests widget et routage Flutter |

#### Environnement d'execution

Le projet est concu pour un environnement local de developpement compose d'un serveur Node.js, d'une base MySQL, d'une application Flutter et d'une interface React separee. Le backend s'execute via `npm run dev` ou `npm start` dans `back-end/`, puis ecoute par defaut sur le port 5001. La base MySQL est initialisee via les scripts SQL du dossier `back-end/sql/`. Le client Flutter peut etre execute en mode Chrome, Android, Windows ou Web selon les commandes `flutter run`. L'application d'administration React est lancee via Vite et communique avec la meme API REST. Des integrations optionnelles existent pour Redis, Firebase et Sentry, selon les variables d'environnement renseignees.

### 3.2 Developpement

#### 3.2.1 Structure du projet

```text
App_Touriste/
|-- back-end/                         <- API REST Node.js / Express et logique metier
|   |-- package.json                  <- dependances serveur et scripts npm
|   |-- .env.example                  <- variables d'environnement de reference
|   |-- server.js                     <- point d'entree HTTP et configuration globale
|   |-- scripts/                      <- scripts de seed, diagnostic et maintenance
|   |-- sql/                          <- schema relationnel, installation et donnees
|   |   |-- create_tables.sql         <- definition des tables, triggers et procedures
|   |   `-- seed_data.sql             <- jeu de donnees initiales
|   |-- src/
|   |   |-- config/                   <- base de donnees, runtime, CORS, constantes
|   |   |-- controllers/              <- adaptation HTTP -> services
|   |   |-- middleware/               <- auth, gestion d'erreur, upload, rate limit
|   |   |-- routes/                   <- endpoints REST regroupes par domaine
|   |   |-- services/                 <- logique metier et acces SQL
|   |   `-- utils/                    <- JWT, validation, medias, helpers
|   `-- tests/                        <- tests backend Mocha / Chai / Supertest
|-- front-end/                        <- application Flutter utilisateur final
|   |-- pubspec.yaml                  <- dependances Flutter et metadata
|   |-- web/                          <- bootstrap web Flutter
|   |-- test/                         <- tests widget et routage
|   `-- lib/
|       |-- main.dart                 <- initialisation generale de l'application
|       |-- core/                     <- constantes, reseau, router, storage, theme
|       |-- features/
|       |   |-- auth/                 <- ecrans et provider d'authentification
|       |   |-- home/                 <- shell principal de navigation
|       |   |-- map/                  <- ecran carte et interactions geographiques
|       |   |-- professional/         <- espace metier pour professionnels
|       |   |-- profile/              <- profil, badges, historique, classement
|       |   `-- sites/                <- catalogue, detail, check-ins, avis
|       `-- shared/                   <- widgets et modeles reutilisables
|-- admin-web/                        <- SPA React d'administration et moderation
|   |-- package.json                  <- dependances et scripts Vite / Vitest
|   |-- src/
|   |   |-- App.jsx                   <- composition des pages et routing admin
|   |   |-- lib/                      <- client API, auth, utilitaires partages
|   |   `-- components/               <- cartes de moderation et widgets dashboard
|   `-- tests/                        <- tests de l'interface admin
|-- .github/
|   `-- workflows/
|       `-- ci.yml                    <- pipeline CI multi-applications
|-- README.md                         <- vue d'ensemble du depot
|-- ANALYSE_PROJET.md                 <- synthese technique du projet
|-- RAPPORT_DETAILLE_APPLICATION.md   <- documentation descriptive de l'application
|-- PFE_RAPPORT_DONNEES.md            <- donnees et matiere pour le rapport PFE
`-- pfe_docs/                         <- documents Markdown generes pour le rapport
```

Cette organisation montre une separation nette des responsabilites. Le backend centralise l'acces aux donnees et les regles de gestion. Le client Flutter se concentre sur l'experience utilisateur grand public et professionnelle. L'interface admin React constitue un outil specialise de moderation. Enfin, la documentation et la CI aident a maintenir la coherence globale du projet.

#### 3.2.2 Implementation des fonctionnalites principales

**Fonctionnalite 1 : Authentification et gestion des sessions**

Description : le backend encapsule la creation de session dans `auth.service.js`. A chaque connexion ou inscription, un access token JWT et un refresh token aleatoire sont generes, puis conserves dans la table `sessions`. Cette approche permet a la fois l'authentification et l'invalidation des anciennes sessions.

Fichier : `back-end/src/services/auth.service.js`

```js
async function createSession(db, user, requestContext = {}) {
  const accessToken = generateToken(user);
  const refreshToken = randomBytes(32).toString('hex');
  const deviceInfo = requestContext.deviceInfo || {};

  await db.query(
    `INSERT INTO sessions (
        id, user_id, access_token, refresh_token, device_type, device_name, device_id,
        os_version, app_version, ip_address, user_agent, country, city, expires_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL ? DAY))`,
    [
      randomUUID(),
      user.id,
      accessToken,
      refreshToken,
      normalizeDeviceType(deviceInfo),
      deviceInfo.device_name || null,
      deviceInfo.device_id || null,
      deviceInfo.os_version || null,
      deviceInfo.app_version || null,
      requestContext.ipAddress || '0.0.0.0',
      requestContext.userAgent || null,
      deviceInfo.country || null,
      deviceInfo.city || null,
      REFRESH_TOKEN_TTL_DAYS
    ]
  );
}
```

Explication : la fonction commence par creer un JWT d'acces et un refresh token pseudo-aleatoire. Elle recupere ensuite les informations de terminal envoyees par le client. La requete SQL insere la session en base avec les donnees techniques utiles a l'audit, a la rotation des jetons et a la deconnexion. Le choix de stocker les sessions en base rend possible la revocation et la detection des sessions inactives.

**Fonctionnalite 2 : Verification de check-in par geolocalisation**

Description : l'une des briques centrales du projet est la verification terrain. Le service de check-in adapte dynamiquement le rayon autorise selon la nature du site et construit des notes de verification conservees avec le check-in.

Fichier : `back-end/src/services/checkin.service.js`

```js
function resolveAllowedDistanceMeters(site = {}) {
  if (isStrictSite(site)) {
    return GPS_VALIDATION.DYNAMIC_DISTANCE_RULES.strict;
  }

  if (isRelaxedSite(site)) {
    return GPS_VALIDATION.DYNAMIC_DISTANCE_RULES.relaxed;
  }

  return GPS_VALIDATION.DYNAMIC_DISTANCE_RULES.standard;
}

function resolveRecommendedAccuracyMeters(site = {}) {
  return isStrictSite(site)
    ? GPS_VALIDATION.STRICT_ACCURACY
    : GPS_VALIDATION.MIN_ACCURACY;
}

function resolveMinimumVisitDurationSeconds(site = {}) {
  if (isStrictSite(site)) {
    return 30;
  }
```

Explication : le service classe d'abord le site dans une strategie de controle stricte, relachee ou standard. Il ajuste ensuite le rayon admissible et la precision GPS minimale en consequence. Cette implementation montre que le check-in n'est pas une simple insertion SQL, mais une verification metier tenant compte du type de lieu visite.

**Fonctionnalite 3 : Routage protege et gestion des roles cote Flutter**

Description : le client Flutter gere les redirections d'acces dans `AppRouter`. Les ecrans sensibles sont proteges par l'etat de connexion et par le role du compte. Le meme routeur distingue les flux visiteur, utilisateur authentifie et professionnel.

Fichier : `front-end/lib/core/router/app_router.dart`

```dart
redirect: (context, state) {
  final location = state.matchedLocation;
  final isAuthenticated = authProvider.isAuthenticated;

  if (location == '/') {
    return null;
  }

  if (!isAuthenticated && isProtectedRoute(location)) {
    return '/login';
  }

  if (isAuthenticated &&
      isProfessionalRoute(location) &&
      !canAccessSiteManagement(authProvider.user?.role)) {
    return '/home';
  }

  if (isAuthenticated && isAuthRoute(location)) {
    return '/home';
  }
```

Explication : le routeur recupere d'abord la route courante et l'etat d'authentification. Il laisse passer la splash route, bloque ensuite les routes protegees pour les visiteurs, empeche l'acces aux ecrans professionnels pour les roles non autorises, puis evite qu'un utilisateur deja connecte revienne vers login ou register. Cette logique centralisee simplifie la securisation de l'interface.

**Fonctionnalite 4 : Catalogue touristique avec filtres et recherche**

Description : `SitesProvider` orchestre la recuperation des sites, des categories, des filtres de ville, de note, de distance et de sous-categories. Le provider construit dynamiquement les parametres HTTP envoyes au backend.

Fichier : `front-end/lib/features/sites/presentation/sites_provider.dart`

```dart
final queryParameters = <String, dynamic>{
  if (trimmedCity?.isNotEmpty ?? false) 'city': trimmedCity,
  if (trimmedSearchQuery.isNotEmpty) 'q': trimmedSearchQuery,
  ...?effectiveCategoryId != null
      ? <String, dynamic>{'category_id': effectiveCategoryId}
      : null,
  ...?effectiveSubcategoryId != null
      ? <String, dynamic>{'subcategory_id': effectiveSubcategoryId}
      : null,
  ...?trimmedSubcategory?.isNotEmpty == true
      ? <String, dynamic>{'subcategory': trimmedSubcategory}
      : null,
  if (effectiveMinimumRating > 0)
    'min_rating': effectiveMinimumRating.toStringAsFixed(1),
  if (effectiveLatitude != null) 'lat': effectiveLatitude,
  if (effectiveLongitude != null) 'lng': effectiveLongitude,
};
```

Explication : le provider ne transmet que les filtres effectivement renseignes. Les operateurs conditionnels de Dart permettent de composer proprement la requete. Cette implementation rend le client souple, car un meme ecran peut piloter le catalogue par ville, par proximite, par categorie ou par note sans multiplier les endpoints.

**Fonctionnalite 5 : Moderation centrale des contenus dans l'espace admin**

Description : l'administration web s'appuie sur des routes backend dediees, toutes protegees par authentification, limitation de debit et verification du role `ADMIN`. Les operations sensibles de moderation sont regroupees dans un meme module.

Fichier : `back-end/src/routes/admin.routes.js`

```js
const router = express.Router();

router.use(adminRateLimit, authMiddleware, authorizeRoles('ADMIN'));

router.get('/sites/pending', asyncHandler(getPendingSites));
router.get('/sites/:id', asyncHandler(getAdminSiteDetailHandler));
router.put('/sites/:id/review', asyncHandler(reviewSiteHandler));
router.get('/reviews/pending', asyncHandler(getPendingReviews));
router.get('/reviews/:id', asyncHandler(getAdminReviewDetailHandler));
router.delete('/reviews/:id/photos/:photoId', asyncHandler(deleteReviewPhotoHandler));
router.put('/reviews/:id/moderate', asyncHandler(moderateReviewHandler));
router.get('/contributor-requests', asyncHandler(getContributorRequestsHandler));
router.patch('/contributor-requests/:id', asyncHandler(reviewContributorRequestHandler));
router.get('/stats', asyncHandler(getAdminStatsHandler));
router.get('/users', asyncHandler(getUsers));
```

Explication : un middleware commun securise toutes les routes du module avant meme la declaration des endpoints. Les actions de moderation couvrent les sites, les avis, les photos associees, les statistiques et les comptes utilisateurs. Ce choix structurel traduit une vraie separation entre l'application grand public et l'outillage de gouvernance.

### 3.3 Presentation de l'application

Les captures d'ecran n'ont pas ete trouvees dans le depot sous un dossier `screenshots/`, `docs/` ou equivalent. Le tableau suivant decrit donc les interfaces principales et precise les captures a produire manuellement lors de la composition du rapport.

| Interface | Route | Description | Capture disponible |
|-----------|-------|-------------|-------------------|
| Splash screen | `/` | Ecran d'initialisation chargeant la configuration, la session et les services de base. | NON |
| Welcome screen | `/welcome` | Ecran d'entree simplifie proposant creation de compte, connexion et acces visiteur. | NON |
| Login screen | `/login` | Formulaire de connexion email / mot de passe, avec entree Google si la configuration Firebase est complete. | NON |
| Register screen | `/register` | Formulaire d'inscription utilisateur avec collecte des informations de base. | NON |
| Home screen | `/home` | Shell principal de l'application, point d'entree vers carte, explorer et profil. | NON |
| Map screen | `/map` | Carte centree sur Agadir affichant les lieux visibles, filtres, resume et marqueurs interactifs. | NON |
| Liste des sites | `/sites` | Catalogue des lieux avec recherche, categories, curations et cartes de previsualisation. | NON |
| Detail d'un site | `/sites/:id` | Fiche complete d'un lieu : image, description, notes, horaires, contact, check-in et avis. | NON |
| Ajout de check-in | `/checkin/:id` | Ecran de verification sur place avec geolocalisation, statut et pieces justificatives. | NON |
| Detail de check-in | `/checkins/:id` | Historique detaille d'un check-in et de ses notes de verification. | NON |
| Ajout d'avis | `/review/:id` | Saisie d'une note, d'un commentaire et de photos d'avis. | NON |
| Profil utilisateur | `/profile` | Resume du compte, statistiques, badges, progression et acces aux historiques. | NON |
| Profil public | `/users/:id` | Consultation du profil public d'un autre utilisateur et de ses statistiques. | NON |
| Mes check-ins | `/profile/checkins` | Historique personnel des validations de terrain avec filtres et statuts. | NON |
| Mes avis | `/profile/reviews` | Historique des avis publies avec acces au site et menu d'actions. | NON |
| Catalogue de badges | `/profile/badges` | Liste des badges obtenables et progression de gamification. | NON |
| Leaderboard | `/leaderboard` | Classement communautaire base sur les points et l'activite. | NON |
| Hub professionnel | `/professional` | Point d'entree pro avec acces rapide et indicateurs metier. | NON |
| Revendiquer un site | `/professional/claims` | Recherche d'un lieu existant et demande de rattachement a un compte pro. | NON |
| Mes etablissements | `/professional/sites` | Liste des lieux geres par un professionnel avec KPI et statuts. | NON |
| Ajouter / modifier un lieu | `/professional/sites/new` et `/professional/sites/:id/edit` | Formulaire segmente pour creer ou mettre a jour une fiche de site. | NON |
| Detail d'un lieu pro | `/professional/sites/:id` | Vue metier d'un etablissement avec etat de validation et mesures business. | NON |
| Admin login | `/login` dans `admin-web` | Authentification administrateur pour acceder au tableau de moderation. | NON |
| Admin dashboard | `/dashboard/overview` | Vue d'ensemble du back-office avec files d'attente et statistiques. | NON |
| Moderation des sites | `/dashboard/sites` | Liste des sites en attente et actions d'approbation, rejet ou archivage. | NON |
| Moderation des avis | `/dashboard/reviews` | Traitement des avis, des photos et des signalements. | NON |
| Demandes contributor | `/dashboard/contributor-requests` | Validation des demandes de changement de role. | NON |
| Gestion des utilisateurs | `/dashboard/users` | Consultation des comptes et mise a jour du role ou du statut. | NON |

Pour le rapport final, il conviendra de capturer au minimum : l'accueil, la connexion, la carte, la liste des sites, la fiche de site, le profil, l'espace professionnel, la moderation admin et un exemple de check-in.

### 3.4 Tests et validation

Le projet dispose de plusieurs niveaux de validation formelle.

- Des tests backend sont implementes dans `back-end/tests/` avec Mocha, Chai et Supertest.
- Des tests front admin existent dans `admin-web/tests/` avec Vitest.
- Des tests Flutter sont presents dans `front-end/test/`.

Les principaux scenarios verifies cote backend sont les suivants :

- inscription d'un nouvel utilisateur ;
- rejet d'un email deja utilise ;
- validation des payloads d'authentification ;
- connexion avec identifiants valides et invalides ;
- rotation du refresh token ;
- recuperation du profil utilisateur ;
- mise a jour du profil ;
- deconnexion et invalidation de session ;
- flux Google cote backend ;
- endpoints de sites, de categories et de moderation.

Resultats observes lors de l'analyse du depot :

- `npm test` dans `back-end/` : 53 tests reussis ;
- `npm test` dans `admin-web/` : 3 tests reussis ;
- `flutter test` dans `front-end/` : execution partiellement en echec a cause de deux assertions de textes devenues obsoletes.

Les deux ecarts constates cote Flutter sont les suivants :

- `test/core/router/app_router_test.dart` attend encore le texte `Connectez-vous a votre compte` ;
- `test/features/sites/site_detail_screen_test.dart` attend encore le libelle `Check-in`, alors que l'ecran actuel affiche `Faire un check-in`.

Aucun taux de couverture n'est fourni explicitement dans le depot. En l'absence de rapport de couverture exporte, la validation s'appuie donc sur les suites de tests presentes, sur `flutter analyze`, sur `node --check`, ainsi que sur les essais manuels deja realises pour les parcours d'authentification, de carte, de consultation des sites et d'affichage des images.

### 3.5 Conclusion

La realisation de MoroccoCheck montre une mise en oeuvre aboutie d'une plateforme fullstack structuree autour d'une API REST, d'un client Flutter et d'un back-office de moderation. Les choix techniques retenus privilegient la separation des responsabilites, la fiabilite des interactions mobiles, la securite d'acces et la possibilite de faire evoluer le produit par domaines fonctionnels.

Les fonctionnalites essentielles - authentification, catalogue de lieux, carte, check-ins, avis, gamification, espace professionnel et moderation - sont concretement implementees dans le code. La phase de validation confirme en outre une base solide, en particulier cote backend. Le chapitre suivant peut donc se concentrer sur la mise en forme editoriale du rapport, la synthese globale du travail et les annexes necessaires a la soutenance.
