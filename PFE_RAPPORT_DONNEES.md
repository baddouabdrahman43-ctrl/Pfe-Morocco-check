# Données pour le rapport PFE — MoroccoCheck

Ce document regroupe les **informations administratives** fournies par l’équipe et les **éléments extraits du dépôt** (code, README, `RAPPORT_DETAILLE_APPLICATION.md`, schémas SQL, CI) pour rédiger un rapport de Projet de Fin d’Études (LaTeX ou autre).

**Sources projet :** `README.md`, `back-end/README.md`, `front-end/README.md`, `RAPPORT_DETAILLE_APPLICATION.md`, `back-end/sql/*.sql`, `back-end/package.json`, `front-end/pubspec.yaml`, `admin-web/package.json`, `.github/workflows/ci.yml`.

---

## PHASE 1 — Informations administratives

| Champ | Valeur |
|--------|--------|
| **Nom du projet** | MoroccoCheck |
| **Sous-titre / description courte** | Plateforme touristique communautaire vérifiée par géolocalisation |
| **Étudiants** | Abderrahmane BADDOU ; Ahmed EL IDRISSI |
| **Filière / spécialité** | Conception et développement des logiciels |
| **Encadrant pédagogique** | Pr. Aïcha BAKKI |
| **Jury** | Pr. Abderrahim SABOUR ; Pr. Aïcha BAKKI |
| **Établissement** | École supérieure de technologie – Agadir |
| **Année universitaire** | 2025–2026 |
| **Logo** | *À fournir : chemin fichier image (établissement ou projet), sinon emplacement réservé dans le rapport* |

---

## PHASE 2 — Contexte et problématique

### 10. Domaine

**Tourisme numérique**, **géolocalisation**, **plateforme communautaire** (avis, check-ins, gamification).

### 11. Contexte et motivation (synthèse projet)

*(Extrait / aligné sur `RAPPORT_DETAILLE_APPLICATION.md` et `README.md`)*

Les touristes et résidents disposent souvent d’informations **fragmentaires**, **peu à jour** ou **peu fiables** sur les lieux à visiter. MoroccoCheck vise à centraliser la découverte des sites touristiques au Maroc, à **vérifier la présence sur place** via le GPS, à enrichir l’expérience par des **avis communautaires** et une **gamification** (points, badges, classement), tout en permettant une **modération** par des administrateurs.

### 12. Problématique (proposition de phrase interrogative)

> **Comment concevoir une plateforme touristique communautaire capable d’améliorer la fiabilité des informations grâce à la géolocalisation, à la participation des utilisateurs et à la modération, tout en restant évolutive sur le plan technique ?**

*(À adapter au style de votre établissement.)*

### 13. Objectifs stratégiques (6 propositions alignées sur le code et la doc)

1. Offrir un **catalogue de sites touristiques** consultable (liste, détail, catégories, carte).
2. Mettre en place une **vérification de présence** sur site via **géolocalisation** (distance, précision, règles dynamiques dans les constantes applicatives).
3. Permettre la **contribution communautaire** : avis, notes, photos (check-in / avis selon implémentation).
4. **Motiver l’engagement** via points, badges, niveaux, rangs et leaderboard.
5. Distinguer les **rôles** (touriste, contributeur, professionnel, admin) et les **parcours** associés (ex. demande touriste → contributeur, espace pro, revendication de site).
6. Assurer la **supervision** : interface d’administration web (stats, modération sites/avis, utilisateurs, demandes contributeur).

### 14. Solutions existantes / concurrents *(à nuancer dans le mémoire, hors dépôt)*

| Solution | Forces (exemples) | Faiblesses (exemples) |
|----------|-------------------|------------------------|
| **TripAdvisor** | Large base d’avis, notoriété | Modération variable ; peu de preuve de présence sur place |
| **Google Maps / Google Travel** | Couverture, itinéraires, avis | Peu spécifique au contexte marocain ; pas d’angle « communauté vérifiée GPS » métier |
| **Guides / blogs** | Contenu éditorial | Pas toujours à jour ; pas d’interaction ni de validation terrain systématique |
| **Réseaux sociaux** | viralité, photos | information dispersée, fiabilité limitée |
| **Apps locales / régionales** *(si citées)* | ancrage local | souvent moins de fonctionnalités de modération ou de gamification intégrées |

*(Compléter avec références bibliographiques en Phase 8.)*

---

## PHASE 3 — Acteurs et besoins

### 15. Acteurs / profils et fonctionnalités principales

| Acteur | Rôle dans le système | Fonctionnalités principales (API / apps) |
|--------|----------------------|------------------------------------------|
| **Visiteur / Touriste** | Utilisateur de base (`TOURIST`) | Inscription, connexion (email ou Google côté mobile), consultation sites, carte, check-in GPS, avis, profil, demande de passage **contributeur** |
| **Contributeur** | Utilisateur enrichissant la communauté (`CONTRIBUTOR`) | Même périmètre élargi selon règles métier (contributions) |
| **Professionnel** | Gestionnaire de lieu (`PROFESSIONAL`) | Espace pro : création / suivi de fiches, **revendication** de site (`claim`), réponse propriétaire aux avis (backend prévu) |
| **Administrateur** | Pilotage et modération (`ADMIN`) | **Admin web** : statistiques, modération sites en attente, modération avis, gestion utilisateurs, traitement des **demandes contributeur** |
| **Système externe** | OAuth / infra | Google Sign-In (tokens validés côté backend), Firebase (mobile), Sentry (monitoring), éventuellement Redis (rate limiting) |

### 16. Besoins fonctionnels (synthèse par domaine)

- **Authentification** : register, login, Google, refresh token, profil, logout ; sessions stockées en base.
- **Sites** : CRUD selon rôle, liste paginée, détail, photos, revues, revendication.
- **Check-ins** : création avec validation GPS (distance Haversine, constantes `GPS_VALIDATION` dans `back-end/src/config/constants.js`).
- **Avis** : CRUD, réponse propriétaire, modération admin.
- **Utilisateur** : badges, stats, leaderboard, changement de mot de passe, demande contributeur.
- **Admin** : endpoints sous `/api/admin/...` (stats, files d’attente modération, utilisateurs).

### 17. Besoins non fonctionnels *(observés dans le projet)*

| Type | Exemples dans MoroccoCheck |
|------|----------------------------|
| **Sécurité** | JWT, sessions actives en BDD, mots de passe hashés (`bcryptjs`), Helmet, CORS configuré, validation (Joi, express-validator), rôles |
| **Performance / scalabilité** | Index SQL sur localisation, catégories, etc. ; rate limiting optionnel (mémoire ou **Redis**) |
| **Disponibilité / monitoring** | Health checks (`/api/health`, `/api/health/db`), logs structurés (Morgan JSON), Sentry (Node & Flutter) |
| **Compatibilité** | API REST JSON ; Flutter multi-plateforme ; admin web React |
| **Maintenabilité** | Architecture en couches (routes → controllers → services), scripts SQL et migrations |
| **UX mobile** | Notifications locales, biométrie optionnelle, synchronisation différée (services offline dans `front-end/lib/core/offline/`) |

---

## PHASE 4 — Architecture et conception

### 18. Architecture technique

- **Style global** : **client–serveur**, **API REST** ; **3 applications** : backend monolithique, client mobile Flutter, SPA admin.
- **Backend** : proche **MVC adapté** — *Routes* → *Controllers* → *Services* + *Middleware* (auth, erreurs, rate limit, upload).
- **Frontend Flutter** : **Provider** pour l’état, **go_router** pour la navigation.
- **Admin** : **React** + **React Router** + **Vite**.

### 19. Technologies (versions indicatives — vérifier `package.json` / `pubspec.yaml` à la date du rapport)

| Catégorie | Technologie |
|-----------|-------------|
| **Backend** | Node.js **20**, **Express 5**, ES modules (`"type": "module"`), **mysql2**, **jsonwebtoken**, **bcryptjs**, **Joi**, **express-validator**, **Helmet**, **CORS**, **Morgan**, **Multer**, **google-auth-library**, **firebase-admin**, **redis** (client), **@sentry/node** |
| **Frontend web (admin)** | **React 18**, **Vite 5**, **React Router 6**, **TypeScript**, **Firebase**, **Sentry** |
| **Application mobile** | **Flutter**, **Dart ≥ 3.10.7**, **Provider**, **go_router**, **Dio**, **geolocator**, **flutter_map**, **Google Sign-In**, **Firebase Auth/Core**, **Sentry Flutter**, notifications, **local_auth**, etc. |
| **Base de données** | **MySQL** (scripts InnoDB, utf8mb4) — nom par défaut `moroccocheck` |
| **Authentification** | **JWT** (Bearer) + **sessions** en base ; refresh token ; **OAuth Google** (idToken côté mobile) |
| **Autres** | **Sentry** (erreurs), **Redis** optionnel (rate limit), **GitHub Actions** (CI), uploads fichiers sous `/uploads` |

### 20. Entités principales de la base de données

*(D’après `back-end/sql/create_tables.sql` et vues associées.)*

| Entité | Attributs / remarques clés |
|--------|----------------------------|
| **categories** | id, name, name_ar, hiérarchie (`parent_id`), couleur, ordre |
| **users** | email, password_hash, profil, **role** (TOURIST, CONTRIBUTOR, PROFESSIONAL, ADMIN), **status**, points, niveau, rank, compteurs, oauth ids |
| **contributor_requests** | demande de rôle contributeur, statut, motivation, validation admin |
| **tourist_sites** | géolocalisation (lat/lon), catégorie, métadonnées lieu, statut publication, modération, propriétaire, fraîcheur (`freshness_score`) |
| **opening_hours** | horaires liés aux sites |
| **checkins** | utilisateur, site, coordonnées, validation GPS, statuts |
| **reviews** | avis, notes, statut (publication / modération), photos |
| **badges** / **user_badges** | gamification |
| **sessions** | jetons d’accès, expiration, activité |
| **favorites** | *(si présent dans schéma complet — voir autres fichiers SQL)* |

### 21. Éléments SQL avancés

- **Vues** : ex. `v_user_stats`, `v_site_details` (`create_views.sql`).
- **Triggers** : mise à jour des compteurs utilisateurs, recalcul notes moyennes sur `tourist_sites` après insert/update/delete sur **checkins** et **reviews** (`create_triggers.sql`).
- **Procédures / install** : voir `install_database.sql`, dossier `sql/migrations/` pour l’évolution du schéma.

### 22. Diagrammes UML

| Diagramme | Statut |
|-----------|--------|
| Cas d’utilisation | *Les fichiers `.puml` historiques ont pu être retirés du dépôt — à refaire ou joindre captures* |
| Classes / séquences / déploiement | *À produire sous outil (PlantUML, StarUML, draw.io) ou insérer captures dans le rapport* |

**Suggestion de figures pour le rapport :** déploiement (Flutter + navigateur admin → API → MySQL), séquence « check-in validé », diagramme de packages backend.

---

## PHASE 5 — Réalisation et interfaces

### 23. Structure du dépôt (principale)

```text
App_Touriste/
├── back-end/          # API Express, src/{config,controllers,middleware,routes,services,utils}, sql/, tests/, uploads/
├── front-end/         # Flutter lib/{core, features, shared, splash}
├── admin-web/         # React + Vite
├── .github/workflows/ # ci.yml
└── README.md
```

### 24. Modules / fonctionnalités clés

| Module | Description | Fichiers / repères |
|--------|-------------|---------------------|
| **API & point d’entrée** | Montage Express, CORS, Helmet, routes, static `/uploads` | `back-end/server.js` |
| **Auth** | Login, register, Google, sessions | `src/controllers/auth.controller.js`, `src/services/auth.service.js`, `src/routes/auth.routes.js` |
| **Sites** | Catalogue, détail, claim pro | `site.controller.js`, `site.service.js` |
| **Check-ins & GPS** | Haversine, rayon | `src/utils/gps.utils.js`, `src/config/constants.js` (`GPS_VALIDATION`) |
| **Avis** | CRUD + modération | `review.service.js`, routes reviews |
| **Admin** | Stats, modération | `admin.routes.js`, `admin.service.js` |
| **Mobile** | UI par feature : auth, sites, map, profile, professional, settings | `front-end/lib/features/**` |
| **Réseau** | Client HTTP | `front-end/lib/core/network/api_service.dart` |

*Extrait représentatif (GPS — à citer dans le rapport avec référence fichier) :*

```javascript
// back-end/src/utils/gps.utils.js — formule de Haversine, isWithinRadius
```

### 25. Interfaces à présenter *(titres issus des écrans Flutter — captures à ajouter)*

| Écran (exemple) | Capture | Description courte | Fonctions (exemples) |
|-----------------|---------|--------------------|----------------------|
| Splash | *chemin image* | Lancement app | Init Firebase, storage, notifications |
| Login / Register | *à capturer* | Authentification | Email, Google, navigation |
| Home | *à capturer* | Accueil | Accès liste, carte, profil |
| Liste des sites | *à capturer* | Catalogue | Filtre, cartes sites |
| Détail site | *à capturer* | Fiche lieu | Avis, itinéraire, check-in |
| Carte | *à capturer* | Carte interactive | Marqueurs, position |
| Check-in | *à capturer* | Validation GPS | Position, photo optionnelle |
| Profil / badges / leaderboard | *à capturer* | Gamification | Stats, classement |
| Espace pro | *à capturer* | Professionnel | Sites, revendication |
| Admin web (dashboard) | *à capturer* | Back-office | Stats, files modération |

### 26. Algorithmes / logique spécifique à détailler dans le mémoire

1. **Distance GPS (Haversine)** et validation **rayon** (mètres) + règles **dynamiques** (`DYNAMIC_DISTANCE_RULES` : strict / standard / relaxed).
2. **Contrôle de précision GPS** et durée minimale de visite (`MIN_ACCURACY`, `DEFAULT_MIN_VISIT_DURATION_SECONDS`) — voir `constants.js` et service check-in.
3. **Hachage mot de passe** et **cycle JWT / refresh** / invalidation session.
4. **Triggers SQL** : cohérence des compteurs et moyennes sans recalcul applicatif systématique.
5. **Synchronisation offline** (file d’attente check-ins / avis côté Flutter — `pending_*_service.dart`).

---

## PHASE 6 — Sécurité, tests, qualité

### 27. Mesures de sécurité *(implémentées ou prévues)*

- **Transport / entêtes** : Helmet, CORS configurable (`src/config/cors.js`, `runtime.js`).
- **Auth** : Bearer JWT ; vérification session active en BDD ; statuts compte (suspendu, banni…).
- **Mots de passe** : hash bcrypt.
- **Validation** : schémas Joi, validateurs, contrôle des uploads (Multer, utilitaires média).
- **Rate limiting** : middleware activable (`RATE_LIMIT_ENABLED`), stockage mémoire ou Redis.
- **Observabilité** : Sentry (backend & Flutter).

### 28. Tests

- **Backend** : **Mocha**, **Chai**, **Supertest** — `npm test` (voir `TEST_DATABASE_SETUP.md` pour base de test).
- **Admin web** : tests Node (`npm test` dans admin-web), **Vitest** en devDependency.
- **Flutter** : `flutter test` / `flutter analyze` (CI).
- **Manuels** : parcours décrits dans `front-end/README.md` et `RAPPORT_DETAILLE_APPLICATION.md`.

### 29. CI/CD *(présent dans le dépôt)*

Fichier **`.github/workflows/ci.yml`** :

- Déclenchement : **push** sur `main` / `master` / `develop`, **pull_request**.
- **Job backend** : Node 20, service **MySQL 8.0**, installation deps, `.env` test, import `install_database.sql`, **migrations**, **`npm test`**.
- **Job admin-web** : `npm ci`, **`npm run build:staging`**.
- **Job Flutter** : Java 17, Flutter stable, **`flutter pub get`**, **`flutter analyze`**, **`flutter build apk`** (flavor staging).

*Pas de déploiement automatique décrit dans ce seul fichier — déploiement production à documenter séparément.*

### 30. Limites actuelles *(README + rapport détaillé)*

- Publication **stores** / industrialisation **production** non finalisées.
- Couverture de **tests** perfectible (frontend surtout).
- Documentation **API** type OpenAPI/Swagger non mentionnée comme livrée.
- Certaines évolutions sont **perspectives** (recommandation intelligente, CI métier avancée, etc.).

### 31. Optimisations de performance

- **Index** SQL sur localisation, clés étrangères, filtres fréquents.
- **Vues** matérialisant des agrégations (`v_user_stats`, `v_site_details`).
- **Rate limiting** pour protéger l’API.
- **Pagination** côté API (selon endpoints — à vérifier dans services).

---

## PHASE 7 — Conclusion et perspectives

### 32. Objectifs : statut *(à cocher lors de la rédaction finale)*

| Objectif | Statut suggéré |
|----------|------------------|
| Plateforme tripartite (API + mobile + admin) | ✓ (code présent) |
| Auth & rôles | ✓ |
| Sites & carte | ✓ |
| Check-in GPS | ✓ |
| Avis & modération | ✓ |
| Gamification | ✓ |
| Déploiement production grand public | ✗ / partiel (selon votre mise en ligne réelle) |

### 33. Difficultés *(à personnaliser — exemples typiques)*

- Intégration **Google Sign-In** / Firebase / alignement **client IDs** backend.
- Gestion **GPS** (précision, cas limites, offline).
- Cohérence **multi-plateformes** (émulateur Android `10.0.2.2`, web, device).
- Coordination **binôme** et priorités fonctionnelles.

### 34. Apports pour l’équipe *(à rédiger)*

- Compétences : **API REST**, **Flutter**, **React**, **MySQL**, **auth**, **CI**, **git**.
- *Compléter avec votre vécu.*

### 35. Améliorations futures *(déjà structurées dans `RAPPORT_DETAILLE_APPLICATION.md`)*

- **Court terme** : OpenAPI, plus de tests E2E, durcissement sessions.
- **Moyen terme** : tableaux de bord admin enrichis, file signalements, audit.
- **Long terme** : recommandations, itinéraires, **tourisme intelligent** intégré.

---

## PHASE 8 — Éléments complémentaires

### 36. Outils de développement

- **IDE** : VS Code / Android Studio / Cursor *(selon usage réel)*.
- **Versionnement** : **Git**, hébergement **GitHub** (`MoroccoCheck`).
- **CI** : **GitHub Actions** (`ci.yml`).
- **Packages** : npm, pub.

### 37. Bibliographie / webographie *(à compléter en format BibTeX ou norme EST)*

Suggestions de sources officielles :

- Documentation **Node.js**, **Express**, **MySQL**, **Flutter**, **Dart**, **React**, **Vite**.
- **JWT** (RFC 7519), **OAuth 2.0** (RFC 6749) — si cités dans le mémoire.
- **Haversine** — article/formule classique en géodésie.

### 38. Dédicace / remerciements

*Champs libres — texte personnalisé par les étudiants.*

### 39. Planification du projet

*À fournir : tableau phases / Gantt / sprints si vous en avez un ; sinon indiquer planning reconstitué.*

### 40. Extraits de code importants *(références prêtes pour `lstlisting` LaTeX)*

| Sujet | Fichier |
|-------|---------|
| Haversine & rayon | `back-end/src/utils/gps.utils.js` |
| Constantes GPS / points | `back-end/src/middleware/auth.middleware.js` |
| Auth JWT + session | `back-end/src/middleware/auth.middleware.js` |
| Entrée Express | `back-end/server.js` |
| Client API Flutter | `front-end/lib/core/network/api_service.dart` |

---

## Notes finales pour la compilation LaTeX

- Figures manquantes : utiliser des cadres réservés `\framebox{[Insérer : …]}` comme prévu dans votre cahier des charges.
- Compiler **deux fois** `pdflatex` pour tables et références croisées.
- Ce fichier **ne remplace pas** la validation de votre encadrant sur la forme institutionnelle (pages de garde, normes EST, etc.).

---

*Document généré pour faciliter la rédaction du rapport PFE — à compléter par les étudiants pour les parties subjectives (difficultés, remerciements, captures d’écran, bibliographie complète).*
