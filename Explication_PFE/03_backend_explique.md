# 03 - Backend Explique

## 1. Role du backend

Le backend est la piece centrale de `MoroccoCheck`. Il recoit les requetes du mobile et de l'admin web, applique la logique metier, controle l'acces aux ressources et dialogue avec la base MySQL.

Le fichier d'entree principal est `back-end/server.js`.

## 2. Structure du backend

La structure generale est la suivante :

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

## 3. Fonction de chaque dossier

### `src/config/`

Contient la configuration technique :

- lecture de l'environnement
- connexion base de donnees
- CORS
- monitoring
- constantes runtime

Exemple important :

- `runtime.js` regroupe `PORT`, `NODE_ENV`, la config DB, JWT, CORS, rate limit et monitoring

### `src/routes/`

Definit les endpoints HTTP. Les routes ne portent pas la logique metier profonde. Elles branchent plutot :

- les middlewares de protection
- les controleurs

### `src/controllers/`

Les controllers recuperent les donnees de la requete et deleguent le traitement principal aux services.

### `src/services/`

Les services contiennent l'essentiel de la logique metier :

- creation et lecture des entites
- calculs
- validations fonctionnelles
- acces SQL

### `src/middleware/`

Ces composants traitent des sujets transverses :

- authentification
- gestion d'erreurs
- rate limiting
- upload
- contexte de requete

### `src/utils/`

On y trouve des utilitaires comme :

- JWT
- mots de passe
- media
- logs
- geolocalisation
- Google auth

## 4. Demarrage du serveur

`server.js` :

- cree l'application Express
- charge Helmet et CORS
- active le parsing JSON
- sert les fichiers uploades
- monte les routes `/api/...`
- branche le middleware d'erreur
- ecoute sur le port defini

L'API locale tourne par defaut sur :

- `http://127.0.0.1:5001`

La route de sante principale est :

- `GET /api/health`

## 5. Modules fonctionnels exposes

Le backend expose plusieurs domaines fonctionnels.

### Authentification

Routes principales :

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/google`
- `POST /api/auth/refresh`
- `GET /api/auth/profile`
- `PUT /api/auth/profile`
- `POST /api/auth/logout`

Le backend gere donc :

- l'inscription classique
- la connexion classique
- la connexion Google
- le rafraichissement de token
- la recuperation du profil
- la mise a jour du profil

### Sites touristiques

Routes principales :

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

Ce module couvre :

- le catalogue public
- le detail d'un site
- les sites lies a un professionnel
- la revendication d'un site
- la creation et mise a jour de fiches

### Check-ins

Routes principales :

- `GET /api/checkins`
- `GET /api/checkins/:id`
- `POST /api/checkins`

Ici, le backend controle une fonctionnalite importante du projet : la validation terrain via geolocalisation.

### Avis

Routes principales :

- `GET /api/reviews`
- `GET /api/reviews/:id`
- `POST /api/reviews`
- `PUT /api/reviews/:id`
- `DELETE /api/reviews/:id`
- `POST /api/reviews/:id/owner-response`

Le projet prend donc en charge :

- publication d'avis
- edition et suppression
- reponse du proprietaire

### Profil et progression

Routes principales :

- `GET /api/users/me`
- `GET /api/users/me/badges`
- `GET /api/users/me/stats`
- `GET /api/users/me/contributor-request`
- `POST /api/users/me/contributor-request`
- `PUT /api/users/me/password`
- `GET /api/badges`
- `GET /api/leaderboard`
- `GET /api/users/:id`

On voit ici la dimension communautaire et gamifiee du projet.

### Administration

Routes principales :

- `GET /api/admin/stats`
- `GET /api/admin/sites/pending`
- `GET /api/admin/sites/:id`
- `PUT /api/admin/sites/:id/review`
- `GET /api/admin/reviews/pending`
- `GET /api/admin/reviews/:id`
- `PUT /api/admin/reviews/:id/moderate`
- `DELETE /api/admin/reviews/:id/photos/:photoId`
- `GET /api/admin/users`
- `GET /api/admin/users/:id`
- `PATCH /api/admin/users/:id/role`
- `PATCH /api/admin/users/:id/status`
- `GET /api/admin/contributor-requests`
- `PATCH /api/admin/contributor-requests/:id`

Ce module est fortement protege car toutes ses routes passent par une verification `ADMIN`.

## 6. Securite et controle d'acces

Le backend met en place plusieurs mecanismes utiles.

### Auth middleware

Le middleware d'authentification verifie les tokens et identifie l'utilisateur courant.

### Authorize roles

Certaines routes exigent un role precis, par exemple :

- `PROFESSIONAL` ou `ADMIN` pour des operations sur des sites
- `ADMIN` pour l'espace d'administration

### Rate limiting

Le backend applique des limites de requetes sur certaines actions sensibles :

- login
- register
- refresh
- admin

### Helmet et CORS

- `Helmet` aide a securiser les headers HTTP
- `CORS` controle les origines autorisees

## 7. Gestion des sessions et tokens

Le backend utilise JWT pour la session applicative. Le code montre egalement :

- une duree de vie configurable
- des routes de refresh
- une table `sessions` en base

Cela permet de presenter une authentification plus solide qu'un simple token statique.

## 8. Gestion des erreurs

Le projet a un middleware d'erreur central.

Interets :

- harmoniser les reponses d'erreur
- eviter les crashs silencieux
- simplifier les controllers

## 9. Monitoring et journalisation

Le backend integre :

- `morgan` pour les requetes HTTP
- des utilitaires de logs
- une possibilite d'activer Sentry

Cela montre une volonte de supervision et pas seulement de developpement local.

## 10. Configuration et environnement

Les variables d'environnement pilotent :

- la base MySQL
- le port
- le secret JWT
- CORS
- les limites de requetes
- la config Google
- le monitoring

Exemples de variables importantes :

- `DB_HOST`
- `DB_USER`
- `DB_PASSWORD`
- `DB_NAME`
- `PORT`
- `JWT_SECRET`
- `JWT_EXPIRES_IN`
- `GOOGLE_CLIENT_IDS`

## 11. Tests backend

Le dossier `tests/` contient des scripts sur plusieurs domaines :

- auth
- admin
- checkins
- categories
- database
- health
- middleware
- reviews
- sites

Le backend n'est donc pas seulement code, il dispose deja d'une base de verification automatisable.

## 12. Lecture critique du backend

### Forces

- structure claire
- separation routes / controllers / services
- prise en charge des roles
- gestion de moderation
- config assez mature
- tests presents

### Limites ou points a consolider

- deploiement production encore a formaliser
- besoin d'une base de donnees bien preparee pour une demo stable
- certaines parties du schema sont plus larges que le scope visible dans l'application

## 13. Comment presenter ce backend en soutenance

Une bonne facon de le presenter est de dire :

- le backend centralise toute la logique metier
- il sert a la fois le mobile et l'admin web
- il applique la securite par JWT et roles
- il dialogue avec MySQL
- il expose des endpoints metiers coherents autour du tourisme, des avis, des check-ins et de la moderation
