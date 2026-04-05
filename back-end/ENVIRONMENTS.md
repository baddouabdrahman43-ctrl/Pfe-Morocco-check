# Environnements Backend

Ce document clarifie les variables d environnement importantes pour le backend MoroccoCheck.

## Environnements Vises

- `development`
- `test`
- `staging`
- `production`

## Variables Critiques

### Serveur

- `PORT`
- `NODE_ENV`

### Base De Donnees

- `DB_HOST`
- `DB_USER`
- `DB_PASSWORD`
- `DB_NAME`
- `DB_PORT`
- `DB_EXIT_ON_FAILURE`

### JWT Et Sessions

- `JWT_SECRET`
- `JWT_EXPIRES_IN`
- `REFRESH_TOKEN_TTL_DAYS`

### Google Auth

- `GOOGLE_CLIENT_IDS`

### CORS

- `CORS_ALLOWED_ORIGINS`
- `CORS_ALLOW_NO_ORIGIN`

### Uploads

- `UPLOAD_DIR`
- `MAX_FILE_SIZE`

### Rate Limiting

- `RATE_LIMIT_ENABLED`
- `RATE_LIMIT_STORE`
- `RATE_LIMIT_REDIS_URL`
- `RATE_LIMIT_REDIS_KEY_PREFIX`
- `RATE_LIMIT_WINDOW_MS`
- `RATE_LIMIT_MAX_REQUESTS`
- `RATE_LIMIT_LOGIN_MAX`
- `RATE_LIMIT_REGISTER_MAX`
- `RATE_LIMIT_ADMIN_MAX`

### Monitoring

- `SENTRY_DSN`
- `SENTRY_ENVIRONMENT`
- `SENTRY_TRACES_SAMPLE_RATE`

## Recommandations Par Environnement

### Development

- `NODE_ENV=development`
- `CORS_ALLOWED_ORIGINS` peut pointer vers les URLs locales du front Flutter web et de l admin web
- `CORS_ALLOW_NO_ORIGIN=true` pour faciliter les appels Postman, mobile natif et scripts locaux

### Test

- utiliser `.env.test` si necessaire
- pointer vers une base dediee de test
- ne jamais reutiliser la base de developpement pour les suites automatisables
- `RATE_LIMIT_ENABLED=false` peut etre utile pour des tests repetitifs si necessaire

### Staging

- utiliser des secrets differents de `development`
- definir explicitement `CORS_ALLOWED_ORIGINS`
- preferer `RATE_LIMIT_STORE=redis` pour coller au comportement multi-instance
- definir explicitement `GOOGLE_CLIENT_IDS` avec les client IDs OAuth autorises
- activer `SENTRY_DSN` avec un projet de preproduction
- verifier les variables JWT et DB avant deploiement

### Production

- `JWT_SECRET` fort et unique
- `CORS_ALLOWED_ORIGINS` explicite
- `CORS_ALLOW_NO_ORIGIN=false`
- `GOOGLE_CLIENT_IDS` explicite et limite aux clients reels de l application
- `RATE_LIMIT_STORE=redis`
- `RATE_LIMIT_REDIS_URL` renseigne
- `SENTRY_DSN` renseigne
- pas de valeurs de demonstration
- acces base et secrets geres hors depot

## Migrations

Les migrations incrementales SQL sont executees via:

```bash
npm run migrate
```

Le statut courant peut etre affiche avec:

```bash
npm run migrate:status
```

## Rotation Du Secret JWT

En cas d exposition ou de doute sur `JWT_SECRET`:

1. generer un nouveau secret fort hors depot
2. mettre a jour le secret dans l environnement cible
3. redemarrer le backend avec la nouvelle valeur
4. invalider les sessions existantes si la politique de securite le demande
5. verifier que `.env` reste non versionne et que seul `.env.example` sert de modele

## Format De CORS_ALLOWED_ORIGINS

Variable attendue:

```env
CORS_ALLOWED_ORIGINS=http://127.0.0.1:5173,http://localhost:5173,https://admin.example.com
```

## Note Sur Les Requetes Sans Origin

Les clients comme:

- applications mobiles natives
- Postman
- scripts serveur a serveur

peuvent envoyer des requetes sans header `Origin`.

Le backend peut les accepter si:

```env
CORS_ALLOW_NO_ORIGIN=true
```

## Google Auth

Le endpoint `POST /api/auth/google` verifie un `id_token` Google cote serveur.

Variable attendue:

```env
GOOGLE_CLIENT_IDS=your-web-client-id.apps.googleusercontent.com
```

Si plusieurs clients OAuth sont autorises a parler au meme backend, la variable peut contenir plusieurs IDs separes par des virgules.
