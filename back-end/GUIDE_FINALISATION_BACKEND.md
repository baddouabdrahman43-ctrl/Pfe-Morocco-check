# Guide de finalisation du backend MoroccoCheck

Ce guide combine le **BACKEND_GUIDE** (conventions, alignement MCD/MPD, workflow) et la **MoroccoCheck_Backend_Roadmap** (étapes détaillées, modules, checklist) pour te donner **une seule feuille de route** pour finaliser le backend de l’application.

**Références** : Dossier_conceptuelle_MC (MCD, MPD, séquences UML, specs API).

---

## Table des matières

1. [Vue d’ensemble et objectif](#1-vue-densemble-et-objectif)
2. [Prérequis et état actuel](#2-prérequis-et-état-actuel)
3. [Architecture et conventions](#3-architecture-et-conventions)
4. [Mapping MCD ↔ backend](#4-mapping-mcd--backend)
5. [Phases de finalisation (étapes détaillées)](#5-phases-de-finalisation-étapes-détaillées)
6. [Sécurité, logging et erreurs](#6-sécurité-logging-et-erreurs)
7. [Tests](#7-tests)
8. [Checklist finale](#8-checklist-finale)
9. [Références](#9-références)

---

## 1. Vue d’ensemble et objectif

- **Objectif** : finaliser le backend MoroccoCheck (API REST) en respectant le MCD/MPD et les séquences du dossier conceptuel.
- **Stack de base** : Node.js 20, Express, MySQL 8, JWT, bcrypt, Joi (ou express-validator).
- **Stack optionnelle (phase avancée)** : Redis (cache, rate limit, sessions), Stripe, S3, SendGrid, Firebase FCM.
- **Livrables** : auth complète, sites touristiques, check-ins GPS, reviews, profil utilisateur, gamification (badges), admin (modération), tests, documentation API, déploiement.

---

## 2. Prérequis et état actuel

### 2.1 Outils requis

| Outil | Version |
|------|---------|
| Node.js | 20.x LTS |
| npm | 10.x |
| MySQL | 8.x |
| Postman / Thunder Client | Pour tester l’API |

### 2.2 Installation et lancement

```bash
cd moroccocheck-backend
npm install
cp .env.example .env
# Remplir .env : DB_*, JWT_SECRET, PORT, NODE_ENV
mysql -u root -p < sql/install_database.sql   # ou scripts create_* + seed_data.sql
npm run dev
```

### 2.3 État actuel du projet

- **Déjà en place** : `server.js`, routes health + auth, controllers auth (register, login, profile), middlewares auth + erreur, config database + constants, utils (gps, validators), sql (tables, triggers, vues, seed).
- **À corriger** : alignement auth/health avec le MPD (noms de colonnes, résultats mysql2, table `tourist_sites`), middleware d’erreur (statusCode).
- **À ajouter** : modules sites, check-ins, reviews, gamification, admin ; optionnel : repositories, Redis, Stripe, S3.

---

## 3. Architecture et conventions

### 3.1 Structure des dossiers (cible)

```
moroccocheck-backend/
├── server.js
├── package.json
├── .env / .env.example
├── sql/
├── src/
│   ├── config/
│   │   ├── database.js
│   │   └── constants.js
│   ├── middleware/
│   ├── routes/
│   ├── controllers/
│   ├── services/           # logique métier (obligatoire)
│   ├── repositories/       # optionnel en phase avancée
│   └── utils/
└── tests/
```

- **Route** → appelle le **controller**.
- **Controller** → valide (Joi ou express-validator), appelle le **service**, renvoie la réponse.
- **Service** → logique métier, règles MCD (distance GPS, cooldown, points, badges). Accède à la DB soit directement (pool), soit via **repository** si tu en ajoutes.

### 3.2 Conventions

- **ES Modules** partout (`import` / `export`).
- **Nommage** : `xxx.controller.js`, `xxx.routes.js`, `xxx.middleware.js`, `xxx.service.js`, `xxx.repository.js`.
- **MPD** : utiliser les noms de colonnes du MPD (`first_name`, `last_name`, `password_hash`, `rank`, `profile_picture`, table `tourist_sites`).
- **mysql2** : `const [rows] = await pool.query(...)` ; première ligne = `rows[0]` ; INSERT = `result.insertId` (via `result` de la déstructuration).

### 3.3 Format des réponses API

- Succès : `{ success: true, data: {...}, message?: string }`.
- Erreur : `{ success: false, message: string, code?: string, details?: any }`.
- Pagination : `{ data: [], meta: { page, limit, total } }`.

---

## 4. Mapping MCD ↔ backend

| Entité MCD | Table | Règles clés |
|------------|-------|-------------|
| USER | `users` | first_name, last_name, password_hash, role, status, points, level, rank |
| TOURIST_SITE | `tourist_sites` | category_id, freshness_score, average_rating, status |
| CHECKIN | `checkins` | RG1 (rôle ≥ CONTRIBUTOR), RG2 (1/jour/site/user), RG4 (distance ≤ 100 m), RG5 (points) |
| REVIEW | `reviews` | RG3 (1 avis/site/user), RG6 (points), recalcul average_rating du site |
| BADGE / USER_BADGE | `badges`, `user_badges` | Attribution après check-in/review |
| CATEGORY | `categories` | Hiérarchie parent_id |
| FAVORITE | `favorites` | user_id, site_id |

---

## 5. Phases de finalisation (étapes détaillées)

Les phases sont à enchaîner dans l’ordre. Chaque phase peut être réalisée avec **controllers + services + pool MySQL** ; la couche **repository** et **Redis/Stripe/S3** sont indiquées comme optionnelles (phase avancée).

---

### Phase 0 — Corriger l’existant (priorité immédiate)

**Objectif** : aligner le code actuel sur le MPD et corriger les bugs identifiés.

| # | Tâche | Détail |
|---|--------|--------|
| 0.1 | Auth : schéma MPD | Utiliser `first_name`, `last_name`, `password_hash`, `rank` (ENUM), `profile_picture`. Supprimer toute référence à `name`, `password`, `avatar_url`, `level` (string). |
| 0.2 | Auth : résultats MySQL | Déstructurer `const [rows] = await pool.query(...)`. Utiliser `rows[0]` pour une ligne, `result[0].insertId` pour un INSERT. Vérifier `emailCheckResult[0][0].count` (ou `rows[0].count`). |
| 0.3 | Health : table sites | Remplacer `sites` par `tourist_sites` dans la requête des stats (`/api/health/db`). Utiliser `tablesResult[0]` pour le tableau des lignes. |
| 0.4 | Middleware erreur | Remplacer `const statusCode` par `let statusCode` dans `error.middleware.js` pour pouvoir réassigner (400, 401, 409). |
| 0.5 | Rôles | Uniformiser la casse (ex. TOURIST, ADMIN en majuscules) entre la base, le JWT et `adminMiddleware`. |

**Livrable** : auth (register, login, profile) et health fonctionnels et cohérents avec le MPD.

---

### Phase 1 — Fondations (utils et config) ✅

**Objectif** : avoir tous les utilitaires nécessaires avant les modules métier.

| # | Tâche | Détail |
|---|--------|--------|
| 1.1 | Utils JWT | `src/utils/jwt.utils.js` : `generateToken(user)`, `verifyToken(token)`. Expiration depuis `JWT_EXPIRES_IN`. |
| 1.2 | Utils password | `src/utils/password.utils.js` : `hashPassword`, `verifyPassword`, `validatePasswordStrength` (optionnel). |
| 1.3 | Utils GPS | `src/utils/gps.utils.js` (ESM) : Haversine, `isWithinRadius` (défaut `GPS_VALIDATION.MAX_DISTANCE`), `formatDistance`. |
| 1.4 | Utils réponses | `src/utils/response.utils.js` : `successResponse`, `paginatedResponse`, `errorResponse`. |
| 1.5 | Validators | `src/utils/validators.js` (ESM) : `registerSchema`, `loginSchema`, `updateProfileSchema`, `checkinSchema`, `reviewSchema`, `siteCreateSchema`, `validateRequest`. |

**Livrable** : utils réutilisables ; validation centralisée. Auth controller et auth middleware utilisent ces utils.

---

### Phase 2 — Module Auth complet

**Objectif** : auth 100 % alignée MPD, prête pour la production.

| # | Tâche | Détail |
|---|--------|--------|
| 2.1 | Register | Valider first_name, last_name, email (unique), password. Hash → password_hash. INSERT avec role TOURIST, points 0, level 1, rank BRONZE. Retourner user (sans password_hash) + token. |
| 2.2 | Login | findByEmail, bcrypt.compare, mettre à jour last_login_at. Retourner user + token. Gérer compte inactif/suspendu. |
| 2.3 | GET/PUT profile | Routes protégées par authMiddleware. GET : profil complet (stats, rank, level). PUT : first_name, last_name, email (unicité), profile_picture. |
| 2.4 | Optionnel | Forgot password / reset (token en BDD ou Redis), vérification email, OAuth Google (voir Roadmap). |

**Endpoints** : `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/auth/profile`, `PUT /api/auth/profile`.

**Livrable** : auth testée (manuellement ou avec tests automatisés).

---

### Phase 3 — Module Sites touristiques

**Objectif** : CRUD et recherche des sites (table `tourist_sites`).

| # | Tâche | Détail |
|---|--------|--------|
| 3.1 | GET liste | Filtres : category_id, city, region, min_rating, status. Pagination (page, limit). Tri par distance si lat/lng fournis (Haversine SQL ou calcul côté app). |
| 3.2 | GET détail | GET `/api/sites/:id`. Détail du site + catégorie. Incrémenter views_count. Optionnel : favori si userId fourni. |
| 3.3 | POST site | Réservé admin ou PROFESSIONAL. Validation (name, category_id, latitude, longitude, address, city, etc.). Statut initial PENDING_REVIEW ou DRAFT. |
| 3.4 | PUT/DELETE site | PUT : mise à jour par propriétaire ou admin. DELETE : soft delete (deleted_at) si prévu en MPD. |
| 3.5 | Constantes | Utiliser `constants.js` (SITE_STATUS, etc.) et table `categories`. |

**Endpoints** : `GET /api/sites`, `GET /api/sites/:id`, `POST /api/sites`, `PUT /api/sites/:id`, `DELETE /api/sites/:id`.

**Livrable** : CRUD sites + liste filtrée et paginée.

---

### Phase 4 — Module Check-ins GPS

**Objectif** : enregistrement d’un check-in avec validation GPS et règles métier.

| # | Tâche | Détail |
|---|--------|--------|
| 4.1 | Service check-in | `createCheckIn(userId, { site_id, status, comment, latitude, longitude, has_photo? })`. 1) Vérifier rôle ≥ CONTRIBUTOR. 2) Vérifier 1 check-in/jour/site/user (requête last check-in today). 3) Charger le site, calculer distance (gps.utils). 4) Si distance > 100 m → erreur. 5) Calculer points (ex. 10 + 5 si photo). 6) INSERT check-in. 7) Mettre à jour user (points, checkins_count, level/rank). 8) Mettre à jour site (freshness_score, last_verified_at). 9) Déclencher vérification badges (phase 6). |
| 4.2 | Route + controller | POST `/api/checkins`. Validation (site_id, status OPEN/CLOSED/UNDER_CONSTRUCTION, lat, lng, comment optionnel). Réponse : checkin + points_earned + message. |
| 4.3 | GET check-ins | GET `/api/checkins` (liste de l’utilisateur connecté, pagination). GET `/api/checkins/:id` (détail). |

**Règles** : RG1, RG2, RG4, RG5 (voir Mapping MCD).

**Livrable** : check-in opérationnel avec validation distance et cooldown.

---

### Phase 5 — Module Reviews (avis)

**Objectif** : dépôt d’avis, recalcul de la note moyenne du site, points et badges.

| # | Tâche | Détail |
|---|--------|--------|
| 5.1 | Service review | `createReview(userId, { site_id, rating, title?, content, visit_date?, photos? })`. 1) Vérifier qu’il n’existe pas déjà un avis pour (userId, site_id). 2) Valider note 1–5, contenu. 3) INSERT review. 4) Recalculer average_rating et total_reviews du site (requête agrégation). 5) Attribuer points (ex. 15–20 selon MCD). 6) Mettre à jour user (points, reviews_count). 7) Vérification badges. |
| 5.2 | Route + controller | POST `/api/reviews`. GET `/api/reviews` (par site ou par user), GET `/api/reviews/:id`. PUT/DELETE (soft) si besoin. |
| 5.3 | Recalcul note site | Fonction ou requête : `AVG(overall_rating)`, `COUNT(*)` sur reviews publiées du site ; UPDATE tourist_sites SET average_rating = ?, total_reviews = ?. |

**Règles** : RG3 (1 avis/site/user), RG6 (points).

**Livrable** : avis créés, note moyenne et total des avis à jour.

---

### Phase 6 — Module Utilisateur (profil) et Gamification

**Objectif** : profil enrichi, niveau/rang, badges.

| # | Tâche | Détail |
|---|--------|--------|
| 6.1 | Profil étendu | GET `/api/users/me` ou `/api/auth/profile` : points, level, rank, checkins_count, reviews_count, liste des badges (avec earned_at). |
| 6.2 | Calcul level/rank | Utiliser les seuils de `constants.js` (RANK_THRESHOLDS). Après chaque action (check-in, review), recalculer points puis level et rank, UPDATE user. |
| 6.3 | Service gamification | `checkAndAwardBadges(userId)` : pour chaque badge actif non encore gagné, vérifier les conditions (nombre de check-ins, reviews, photos, points…). Si OK, INSERT dans user_badges et optionnellement créer une notification. |
| 6.4 | Endpoints badges | GET `/api/badges` (liste des badges). GET `/api/users/me/badges` (badges gagnés par l’utilisateur). Optionnel : GET `/api/leaderboard` (classement par points). |

**Livrable** : profil avec stats et badges ; attribution automatique des badges après check-in/review.

---

### Phase 7 — Module Administration (modération)

**Objectif** : routes réservées aux rôles MODERATOR / ADMIN.

| # | Tâche | Détail |
|---|--------|--------|
| 7.1 | Middleware authorize | Vérifier `req.user.role` (ou req.userRole). Ex. `authorize('ADMIN')` ou `authorize(['ADMIN','MODERATOR'])`. Répondre 403 si non autorisé. |
| 7.2 | Sites en attente | GET `/api/admin/sites/pending`. Valider ou rejeter un site (PUT avec verification_status, notes). |
| 7.3 | Modération avis | GET `/api/admin/reviews/pending`. Approuver / rejeter / masquer (moderation_status, notes). |
| 7.4 | Gestion utilisateurs | GET `/api/admin/users` (filtres, pagination). Suspendre / bannir (mise à jour status, optionnel table user_bans). |
| 7.5 | Dashboard | GET `/api/admin/stats` : nb users, nb sites, nb check-ins récents, nb reviews en attente (pour affichage dashboard). |

**Livrable** : modération sites et avis ; gestion utilisateurs ; stats admin.

---

### Phase 8 — Optionnel : services externes et évolutions

À faire selon les besoins du produit.

| # | Tâche | Détail |
|---|--------|--------|
| 8.1 | Redis | Cache listes de sites (TTL 5 min), cache profil public (TTL 10 min), rate limiting (ex. 5 tentatives login / 15 min), sessions/refresh tokens. |
| 8.2 | Stripe | Abonnements pros : plans (BASIC, PRO, PREMIUM), création abonnement, webhook (invoice.payment_succeeded, subscription.deleted). |
| 8.3 | Upload médias | Multer + stockage local ou S3. Limite 5 Mo, types image. Associer les photos aux check-ins, reviews, profil (table photos ou champs URL). |
| 8.4 | Notifications | Table notifications ; envoi email (SendGrid/Nodemailer) pour bienvenue, reset password ; optionnel push FCM. |
| 8.5 | Couche Repository | Si le projet grossit : déplacer les requêtes SQL dans des repositories (UserRepository, SiteRepository, etc.) et les appeler depuis les services. |

---

### Phase 9 — Tests

| # | Tâche | Détail |
|---|--------|--------|
| 9.1 | Dépendances | Ajouter Mocha + Chai + Supertest (ou Jest + Supertest). Script `npm test`. |
| 9.2 | Tests auth | Register (succès, email déjà utilisé). Login (succès, mauvais mot de passe). Profile (GET/PUT avec token valide, 401 sans token). |
| 9.3 | Tests health | GET /api/health, /api/health/db (connexion, tables, stats avec tourist_sites). |
| 9.4 | Tests check-in | Création avec coordonnées valides (< 100 m) ; rejet si > 100 m ; rejet si déjà check-in aujourd’hui pour ce site. |
| 9.5 | Tests review | Création ; rejet si avis déjà existant pour ce user+site. |

**Livrable** : suite de tests exécutable ; couverture minimale sur auth, health, check-in, review.

---

### Phase 10 — Documentation API et déploiement

| # | Tâche | Détail |
|---|--------|--------|
| 10.1 | Documentation | Swagger/OpenAPI à partir de `Phase3_4_Specifications_API.md`. Décrire tous les endpoints (auth, sites, checkins, reviews, admin). |
| 10.2 | Health | S’assurer que GET `/api/health` (et /api/health/db, /api/health/system) répond correctement pour les sondes de déploiement. |
| 10.3 | Déploiement | .env de production (secrets, CORS, NODE_ENV=production). Optionnel : Dockerfile, docker-compose (app + MySQL (+ Redis)). PM2 ou équivalent pour la prod. |
| 10.4 | .env.example | Documenter toutes les variables utilisées (DB, JWT, PORT, optionnel Redis, Stripe, S3, etc.). |

**Livrable** : API documentée ; backend déployable et monitorable.

---

## 6. Sécurité, logging et erreurs

- **JWT** : secret dans `.env`, expiration cohérente. Vérification sur toutes les routes protégées.
- **Mots de passe** : bcrypt uniquement (saltRounds ≥ 10).
- **Validation** : Joi ou express-validator sur toutes les entrées (auth, check-in, review, site).
- **CORS** : en production, restreindre aux origines autorisées (app mobile, dashboard).
- **Helmet** : activé.
- **Rate limiting** : recommandé sur login/register (ex. 5 req / 15 min par IP) ; implémentation en mémoire ou Redis (phase 8).
- **Logging** : morgan en dev ; en prod éviter de logger des données sensibles.
- **Erreurs** : middleware global ; en prod ne pas exposer stack ni détails internes ; utiliser des codes HTTP et des messages génériques.

---

## 7. Tests

- **Outils** : Mocha + Chai + Supertest (ou Jest + Supertest).
- **Périmètre minimal** : auth (register, login, profile), health, check-in (cas nominal + distance + cooldown), review (création + unicité).
- **Objectif** : au moins les parcours critiques couverts et `npm test` vert.

---

## 8. Checklist finale

Cocher au fur et à mesure de la finalisation.

### Sécurité
- [ ] Mots de passe hashés bcrypt (saltRounds ≥ 10)
- [ ] JWT avec secret dans .env et expiration configurée
- [ ] Validation des entrées (Joi ou express-validator) sur tous les endpoints critiques
- [ ] CORS restreint en production
- [ ] Helmet activé
- [ ] Aucun secret en dur dans le code

### Métier (MCD/MPD)
- [ ] Auth alignée MPD (first_name, last_name, password_hash, rank, profile_picture)
- [ ] Check-in : distance ≤ 100 m, 1 check-in/jour/site/user, rôle ≥ CONTRIBUTOR
- [ ] Review : 1 avis/site/user, recalcul average_rating et total_reviews du site
- [ ] Points et level/rank mis à jour après check-in et review
- [ ] Badges vérifiés et attribués après chaque action concernée
- [ ] Health DB utilise la table `tourist_sites`

### API
- [ ] Format de réponse uniforme (success, data, message / error)
- [ ] Codes HTTP cohérents (201, 400, 401, 403, 404, 409, 500)
- [ ] Pagination sur les listes (page, limit, total)

### Code
- [ ] Résultats mysql2 correctement déstructurés (rows[0], result.insertId)
- [ ] Middleware d’erreur avec statusCode modifiable (let)
- [ ] Rôles en cohérence (base + JWT + middlewares)

### Livrables
- [ ] Phase 0 : corrections existant
- [ ] Phase 2 : auth complète
- [ ] Phase 3 : CRUD sites
- [ ] Phase 4 : check-ins GPS
- [ ] Phase 5 : reviews
- [ ] Phase 6 : profil + gamification (badges, level, rank)
- [ ] Phase 7 : admin (modération)
- [ ] Phase 9 : tests automatisés
- [ ] Phase 10 : documentation API + déploiement

---

## 9. Références

| Document (Dossier_conceptuelle_MC) | Contenu |
|------------------------------------|--------|
| `modélisation_BD/Phase2_1_MCD_Modele_Conceptuel.md` | Entités, relations, règles de gestion |
| `modélisation_BD/Phase2_3_MPD_Scripts_SQL.md` | Scripts SQL (tables, vues, triggers, seeds) |
| `Conception_UML/Diagramme de sequences/Phase1_Conception_Detaillee_Suivi.md` | Séquences (inscription, check-in, avis, etc.) |
| `spécifications-des-apis/Phase3_4_Specifications_API.md` | Spécifications des endpoints API |
| `Architecture_Technique/Phase3_1_Architecture_Systeme_Securite.md` | Architecture et sécurité |

---

**Ordre recommandé** : Phase 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 9 → 10. Phase 8 (Redis, Stripe, S3, etc.) en fonction des besoins produit.

*Guide unifié — MoroccoCheck Backend — À jour avec le Dossier_conceptuelle_MC.*
