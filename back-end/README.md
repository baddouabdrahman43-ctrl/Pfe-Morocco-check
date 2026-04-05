# MoroccoCheck Backend

API REST du projet MoroccoCheck.

Le backend centralise:

- authentification et sessions
- gestion des utilisateurs
- catalogue de sites touristiques
- check-ins GPS
- avis et reponses proprietaires
- badges, stats et leaderboard
- moderation admin
- demandes `TOURIST -> CONTRIBUTOR`

## Stack

- Node.js 20
- Express 5
- MySQL via `mysql2`
- JWT
- `bcryptjs`
- Joi
- Helmet
- CORS
- Morgan

## Demarrage Local

```bash
cd back-end
npm install
cp .env.example .env
npm run dev
```

Le backend demarre par defaut sur:

- `http://127.0.0.1:5001`
- `http://127.0.0.1:5001/api/health`

## Base De Donnees

Le schema SQL est dans `sql/`.

Fichiers importants:

- `create_tables.sql`
- `create_tables_part1.sql` a `create_tables_part4.sql`
- `create_views.sql`
- `create_triggers.sql`
- `seed_data.sql`
- `install_database.sql`

La base locale attendue par defaut est:

- `DB_NAME=moroccocheck`

## Scripts NPM

```bash
npm start
npm run dev
npm test
npm run seed:agadir
npm run migrate
npm run migrate:status
```

## Variables D Environnement

Voir [.env.example](/C:/Users/User/App_Touriste/back-end/.env.example).

Variables principales:

- `PORT`
- `NODE_ENV`
- `DB_HOST`
- `DB_USER`
- `DB_PASSWORD`
- `DB_NAME`
- `DB_PORT`
- `JWT_SECRET`
- `JWT_EXPIRES_IN`
- `REFRESH_TOKEN_TTL_DAYS`
- `CORS_ALLOWED_ORIGINS`
- `CORS_ALLOW_NO_ORIGIN`
- `RATE_LIMIT_ENABLED`
- `GOOGLE_CLIENT_IDS`

Voir aussi:

- [ENVIRONMENTS.md](/C:/Users/User/App_Touriste/back-end/ENVIRONMENTS.md)
- [../ENVIRONMENTS.md](/C:/Users/User/App_Touriste/ENVIRONMENTS.md)
- [sql/migrations/README.md](/C:/Users/User/App_Touriste/back-end/sql/migrations/README.md)

## Routes Principales

### Sante

- `GET /api/health`
- `GET /api/health/db`
- `GET /api/health/system`

### Auth

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/google`
- `POST /api/auth/refresh`
- `GET /api/auth/profile`
- `PUT /api/auth/profile`
- `POST /api/auth/logout`

### Categories

- `GET /api/categories`

### Sites

- `GET /api/sites`
- `GET /api/sites/:id`
- `GET /api/sites/:id/reviews`
- `GET /api/sites/:id/photos`
- `GET /api/sites/mine`
- `GET /api/sites/mine/:id`
- `POST /api/sites`
- `PUT /api/sites/:id`
- `DELETE /api/sites/:id`
- `POST /api/sites/:id/claim`

### Check-ins

- `GET /api/checkins`
- `GET /api/checkins/:id`
- `POST /api/checkins`

### Avis

- `GET /api/reviews`
- `GET /api/reviews/:id`
- `POST /api/reviews`
- `PUT /api/reviews/:id`
- `DELETE /api/reviews/:id`
- `POST /api/reviews/:id/owner-response`

### Utilisateurs

- `GET /api/badges`
- `GET /api/leaderboard`
- `GET /api/users/me`
- `GET /api/users/me/badges`
- `GET /api/users/me/stats`
- `GET /api/users/me/contributor-request`
- `POST /api/users/me/contributor-request`
- `PUT /api/users/me/password`
- `GET /api/users/:id`

### Admin

- `GET /api/admin/stats`
- `GET /api/admin/sites/pending`
- `GET /api/admin/sites/:id`
- `PUT /api/admin/sites/:id/review`
- `GET /api/admin/reviews/pending`
- `GET /api/admin/reviews/:id`
- `PUT /api/admin/reviews/:id/moderate`
- `DELETE /api/admin/reviews/:id/photos/:photoId`
- `GET /api/admin/users`
- `PATCH /api/admin/users/:id/status`
- `GET /api/admin/contributor-requests`
- `PATCH /api/admin/contributor-requests/:id`

## Tests

Les tests backend utilisent Mocha, Chai et Supertest.

```bash
npm test
```

Certaines suites demandent une base de test reelle. Voir:

- [TEST_DATABASE_SETUP.md](/C:/Users/User/App_Touriste/back-end/TEST_DATABASE_SETUP.md)

## Structure Technique

```text
back-end/
|- server.js
|- src/
|  |- config/
|  |- controllers/
|  |- middleware/
|  |- routes/
|  |- services/
|  |- utils/
|- sql/
|- tests/
```

## Notes

- le backend est fonctionnel en local, mais la preparation production fait partie du plan de livraison
- pour le scope metier et les roles, voir:
  - [SCOPE_V1.md](/C:/Users/User/App_Touriste/SCOPE_V1.md)
  - [ROLES_ET_PERMISSIONS.md](/C:/Users/User/App_Touriste/ROLES_ET_PERMISSIONS.md)
