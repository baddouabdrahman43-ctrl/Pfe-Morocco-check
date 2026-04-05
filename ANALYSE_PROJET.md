# Analyse complète du projet App_Touriste / MoroccoCheck

**Date d'analyse :** 5 mars 2025  
**Workspace :** `c:\Users\User\App_Touriste`

---

## 1. Vue d'ensemble

### 1.1 Structure du projet

Le projet **App_Touriste** contient principalement une application backend :

| Composant | Description |
|-----------|-------------|
| **moroccocheck-backend** | API REST Node.js/Express pour l'application MoroccoCheck |
| **.vscode/** | Configuration de l’éditeur (settings.json) |

Il n’y a **pas de frontend** ou d’application mobile dans ce workspace ; le backend est conçu pour servir une app mobile (touristes, vérification GPS des sites au Maroc).

### 1.2 Objectif métier

**MoroccoCheck** est une API permettant :
- aux **touristes** et habitants de vérifier en temps réel la disponibilité et la qualité des sites touristiques au Maroc ;
- la **vérification GPS** (présence sur site) ;
- un système de **notation**, **avis**, **badges** et **gamification**.

---

## 2. Stack technique

| Couche | Technologies |
|--------|--------------|
| **Runtime** | Node.js v20.x (ES Modules) |
| **Framework** | Express 5.x |
| **Base de données** | MySQL 8 (driver `mysql2`) |
| **Authentification** | JWT (`jsonwebtoken`), `bcryptjs` |
| **Validation** | Joi, express-validator |
| **Sécurité / HTTP** | Helmet, CORS |
| **Logs** | Morgan |
| **Upload** | Multer |
| **Dev** | Nodemon |

Le projet utilise **ES Modules** (`"type": "module"` dans `package.json`).

---

## 3. Architecture du backend

```
moroccocheck-backend/
├── server.js                 # Point d'entrée Express
├── package.json
├── .env / .env.example
├── sql/                      # Scripts SQL (création, seed, procédures, vues, triggers)
│   ├── create_database.sql
│   ├── create_tables.sql (part1–4)
│   ├── create_functions.sql, create_procedures.sql, create_triggers.sql
│   ├── create_views.sql
│   ├── seed_data.sql
│   └── install_database.sql
├── src/
│   ├── config/
│   │   ├── database.js       # Pool MySQL
│   │   └── constants.js      # Rôles, statuts, points, GPS...
│   ├── middleware/
│   │   ├── auth.middleware.js   # JWT + admin
│   │   └── error.middleware.js # 404, erreur globale, asyncHandler
│   ├── controllers/
│   │   └── auth.controller.js  # register, login, getProfile, updateProfile
│   ├── routes/
│   │   ├── health.routes.js     # /api/health, /db, /system
│   │   └── auth.routes.js      # /api/auth/*
│   ├── utils/
│   │   ├── gps.utils.js        # Haversine, isWithinRadius, formatDistance
│   │   └── validators.js       # Schémas Joi (non utilisés par l’auth)
│   └── (models/, services/ prévus mais absents)
└── tests/
    ├── test-auth.js
    ├── test-database.js
    ├── test-middleware.js
    └── TESTS_POSTMAN_AUTH.md
```

---

## 4. Base de données (schéma SQL)

### 4.1 Tables principales

- **categories** – Catégories de sites (arborescence, i18n)
- **users** – Utilisateurs (rôles, statuts, points, niveau, rank, OAuth, vérification email/tel)
- **tourist_sites** – Sites touristiques (coordonnées, adresse, catégorie, statut…)
- **checkins** – Vérifications GPS (présence sur site)
- **reviews** – Avis et notes
- **badges** – Gamification
- Autres tables liées (ex. photos, modération, etc.)

### 4.2 Schéma `users` (SQL)

- `password_hash`, `first_name`, `last_name`
- `role` : TOURIST, CONTRIBUTOR, PROFESSIONAL, MODERATOR, ADMIN
- `rank` : BRONZE, SILVER, GOLD, PLATINUM
- `level` : entier (pas une chaîne)
- Pas de colonne `name` ni `password`

---

## 5. Points forts

1. **README** clair (installation, stack, variables d’env, prochaines étapes).
2. **Séparation** config / middleware / controllers / routes / utils.
3. **Sécurité** : Helmet, CORS, JWT, bcrypt, validation Joi sur l’auth.
4. **Health check** : `/api/health`, `/api/health/db`, `/api/health/system`.
5. **Constantes** centralisées (`constants.js`) pour rôles, statuts, points, GPS.
6. **Utilitaires GPS** (Haversine, rayon, formatage) prêts pour les check-ins.
7. **Gestion d’erreurs** centralisée (404, handler global, messages selon le type d’erreur).
8. **Scripts SQL** structurés (tables, vues, procédures, triggers, seed).
9. **Tests** prévus (Mocha/Chai/Supertest) pour l’auth et la DB.

---

## 6. Problèmes et incohérences critiques

### 6.1 Incompatibilité schéma SQL ↔ code (auth)

Le contrôleur d’auth et le schéma SQL ne sont pas alignés :

| Attendu par le code (auth) | Schéma SQL réel |
|----------------------------|-----------------|
| `name` | `first_name` + `last_name` |
| `password` | `password_hash` |
| `level` (string ex. "Bronze") | `level` (INT) + `rank` (ENUM BRONZE, SILVER…) |
| `avatar_url` | `profile_picture` |

**Conséquences :**
- Les requêtes `INSERT`/`SELECT`/`UPDATE` sur `users` échouent ou sont incorrectes si la base a été créée avec les scripts SQL fournis.
- Il faut soit adapter le **code** au schéma SQL (first_name, last_name, password_hash, rank, profile_picture), soit adapter le **schéma** au code (name, password, level, avatar_url), puis uniformiser partout.

### 6.2 Utilisation des résultats MySQL2

Avec `mysql2` (promise), `pool.query()` retourne **`[rows, fields]`** :

- `result[0]` = tableau des lignes  
- Pour un `SELECT` d’une ligne : `result[0][0]` = premier enregistrement  
- Pour un `INSERT` : `result[0]` = `ResultSetHeader` (avec `insertId`)

Dans le code actuel :

- **auth.controller.js**
  - `emailCheckResult[0].count` → doit être `emailCheckResult[0][0].count` (ou déstructurer `const [rows] = await pool.query(...)` puis `rows[0].count`).
  - `userResult.length === 0` → toujours faux (length = 2). Il faut tester `userResult[0].length === 0` et utiliser `userResult[0][0]` comme utilisateur.
  - `insertResult.insertId` → doit être `insertResult[0].insertId`.
  - Idem pour tous les `pool.query` : accès aux lignes via `result[0]` et à la première ligne via `result[0][0]`.
- **health.routes.js**
  - `tablesResult.map(row => ...)` → `tablesResult` est `[rows, fields]`, il faut `tablesResult[0].map(...)`.
  - `statsResult[0]` → donne le premier **élément** du tableau de lignes ; si une seule ligne de stats, c’est correct pour le contenu, mais le nom est trompeur (mieux : `const [rows] = await pool.query(...); const stats = rows[0]`).

Sans ces corrections, l’auth et le health check DB peuvent planter ou renvoyer des données incorrectes.

### 6.3 Health check : noms de tables

Dans `health.routes.js`, les statistiques utilisent la table **`sites`** :

```javascript
(SELECT COUNT(*) FROM sites) as sites
```

Alors que le schéma SQL définit **`tourist_sites`**. Il faut remplacer `sites` par `tourist_sites` (ou créer une vue `sites` si voulu).

### 6.4 Middleware d’erreur : `statusCode` en lecture seule

Dans `error.middleware.js` :

```javascript
const statusCode = err.statusCode || err.status || 500;
// ...
} else if (err.name === 'ValidationError') {
  statusCode = 400;  // ❌ réassignation d'une const
```

`statusCode` est déclaré en `const`, donc toute réassignation est interdite. Les codes 400, 401, 409 ne sont jamais appliqués. Il faut utiliser une variable `let statusCode` pour pouvoir la modifier dans les branches.

### 6.5 Utilitaires : mélange de modules

- **gps.utils.js** et **validators.js** utilisent `module.exports` (CommonJS) alors que le reste du projet est en **ESM** (`import`/`export`). Cela peut poser problème selon la config Node (ou il faudra les importer via `createRequire`). À uniformiser en ESM.

### 6.6 Rôle admin

- **auth.middleware.js** : `adminMiddleware` vérifie `req.userRole !== 'ADMIN'`.
- En base, le rôle est en **MAJUSCULES** (TOURIST, ADMIN, etc.). À l’inscription, le contrôleur met `role: 'tourist'` (minuscules). Il faut être cohérent (tout en majuscules côté DB et JWT, ou tout en minuscules) pour que la vérification admin fonctionne.

### 6.7 Dépendances des tests

Les tests (ex. `test-auth.js`) utilisent **Mocha**, **Chai**, **Supertest**, qui ne sont **pas** listés dans `package.json`. Les commandes `npm test` / `npm run lint` du README ne peuvent pas fonctionner sans ajout de ces dépendances et d’un script de test.

---

## 7. Sécurité et configuration

- **.env** : ne pas commiter (à garder en `.gitignore`).  
- **.env.example** : présent (DB, JWT, upload, rate limiting).  
- **JWT** : expiration 7j, secret à définir en production.  
- **Rate limiting** : variables présentes dans `.env.example` mais pas de middleware Express dédié dans le code analysé → à implémenter si souhaité.  
- **CORS** : activé sans restriction d’origine ; en production, limiter aux origines de l’app mobile / web.

---

## 8. Fonctionnalités prévues mais absentes

D’après le README et la structure :

- Contrôleurs **sites touristiques**, **check-ins GPS**, **reviews**, **badges**
- **Models** et **services** (dossiers vides ou non utilisés)
- **Notifications**
- **Documentation API** (Swagger/OpenAPI)
- **Rate limiting** effectif
- **Tests** exécutables (Jest mentionné dans le README, Mocha dans les fichiers)

---

## 9. Recommandations prioritaires

1. **Aligner schéma DB et code**  
   Choisir un seul modèle (celui du SQL ou celui du code) et l’appliquer partout (users : first_name/last_name ou name, password_hash ou password, rank/level, profile_picture ou avatar_url).

2. **Corriger l’usage des résultats mysql2**  
   Partout : déstructurer `const [rows] = await pool.query(...)` et utiliser `rows[0]` pour la première ligne, `result[0].insertId` pour l’INSERT.

3. **Corriger le middleware d’erreur**  
   Remplacer `const statusCode` par `let statusCode` pour pouvoir attribuer 400, 401, 409 selon le type d’erreur.

4. **Health check**  
   Remplacer `sites` par `tourist_sites` dans la requête des stats.

5. **Uniformiser les modules**  
   Passer `gps.utils.js` et `validators.js` en ESM et les utiliser depuis les contrôleurs (ex. réutiliser les schémas de `validators.js` dans l’auth si souhaité).

6. **Rôles**  
   Uniformiser la casse (ex. tout en majuscules comme en base) et s’assurer que le JWT et `adminMiddleware` utilisent la même valeur.

7. **Tests**  
   Ajouter Mocha, Chai, Supertest (ou Jest) dans `package.json` et un script `npm test` qui lance les tests existants.

8. **Documentation**  
   Une fois l’API stabilisée, ajouter Swagger/OpenAPI pour les routes auth et health, puis les futures routes (sites, check-ins, reviews).

---

## 10. Synthèse

| Critère | État |
|--------|------|
| **Structure / architecture** | Bonne base (config, routes, middleware, controllers) |
| **Sécurité (auth, JWT, bcrypt)** | Bonne intention, à corriger selon le schéma et les résultats MySQL |
| **Cohérence code / DB** | À corriger (users, noms de colonnes, tables) |
| **Résultats MySQL2** | À corriger partout (accès aux lignes et insertId) |
| **Gestion d’erreurs** | Bonne structure, bug sur `statusCode` à corriger |
| **Tests** | Présents mais dépendances et script manquants |
| **Fonctionnalités métier** | Auth et health en place ; sites, check-ins, reviews, badges à développer |

En résumé : le projet est bien structuré et la direction (stack, sécurité, séparation des couches) est bonne, mais **plusieurs bugs bloquants** (schéma vs code, utilisation de `pool.query`, statusCode) doivent être corrigés pour que l’auth et le health check soient fiables. Ensuite, la priorité peut être d’implémenter les contrôleurs et routes pour les sites touristiques, check-ins GPS et avis, en s’appuyant sur les constantes et les utilitaires GPS déjà présents.
