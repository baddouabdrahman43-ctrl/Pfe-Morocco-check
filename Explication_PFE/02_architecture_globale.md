# 02 - Architecture Globale

## 1. Vue d'ensemble

Le depot est organise autour de trois briques applicatives principales :

```text
App_Touriste/
|- back-end/
|- front-end/
|- admin-web/
```

Chaque brique a une responsabilite bien definie.

## 2. Role de chaque sous-projet

### `back-end/`

C'est le coeur technique du systeme. Le backend centralise :

- l'authentification
- les sessions
- la logique metier
- l'acces a la base MySQL
- les routes API
- la moderation admin

### `front-end/`

C'est l'application Flutter orientee utilisateur final. Elle sert a :

- afficher les sites
- permettre l'inscription et la connexion
- lancer les check-ins
- envoyer les avis
- afficher le profil, les badges et le classement
- proposer un espace professionnel de base

### `admin-web/`

C'est une application React/Vite reservee aux administrateurs. Elle sert a :

- piloter la moderation
- consulter les files d'attente
- traiter les comptes et les demandes contributor
- suivre quelques statistiques globales

## 3. Schema de circulation des donnees

```text
Mobile Flutter -------------------+
                                  |
                                  v
                         API REST Express
                                  |
                                  v
                               MySQL
                                  ^
                                  |
Admin Web React ------------------+
```

Le backend joue donc le role de point central :

- il expose les endpoints
- il verifie l'authentification
- il applique les regles metier
- il lit et ecrit dans la base

## 4. Architecture logique

L'architecture suit une separation classique en couches.

### Cote backend

```text
Routes -> Controllers -> Services -> Base de donnees
```

En plus de cela, on trouve :

- des middlewares transverses
- des utilitaires
- des configurations runtime

### Cote mobile

Le front Flutter s'appuie sur une structure par fonctionnalite :

- auth
- sites
- map
- profile
- professional

Chaque fonctionnalite combine generalement :

- ecrans de presentation
- modeles
- appels API
- gestion d'etat

### Cote admin web

L'admin web suit une logique SPA :

- une couche de session
- un routeur React
- un client API
- des ecrans de dashboard
- des composants reutilisables

## 5. Stack technique

### Backend

- Node.js
- Express 5
- MySQL
- JWT
- bcryptjs
- Joi
- Helmet
- CORS
- Morgan
- Sentry

### Front mobile

- Flutter
- Dart
- Provider
- GoRouter
- Dio
- Google Sign-In
- Firebase
- Geolocator
- Flutter Map
- Flutter Secure Storage

### Admin web

- React 18
- Vite
- React Router
- Firebase
- fetch API

## 6. Principes d'architecture visibles dans le code

Le projet montre plusieurs bons choix structurants :

- separation claire des applications
- backend unique pour les clients mobile et web
- reutilisation du meme modele de roles
- parametrage par variables d'environnement
- gestion de sessions et tokens
- prise en compte de la moderation

## 7. Gestion des roles

Le projet manipule plusieurs roles :

- `TOURIST`
- `CONTRIBUTOR`
- `PROFESSIONAL`
- `ADMIN`

Ces roles influencent :

- les routes protegees du front mobile
- les actions disponibles cote backend
- l'acces au dashboard admin
- les operations sur les sites et les contenus

## 8. Environnements et execution

Le projet distingue plusieurs contextes d'execution :

- `development`
- `staging`
- `production`

Sur Android, le front Flutter utilise des flavors :

- `staging`
- `production`

Ce point est important pour un PFE car il montre que le projet pense deja a une industrialisation minimale.

## 9. Points forts de cette architecture

- bon decouplage entre clients et API
- possibilite de faire evoluer le mobile sans toucher a l'admin web
- administration separee du produit utilisateur
- base relationnelle adaptee a un domaine riche
- presence de tests backend et Flutter

## 10. Points d'attention

Quelques sujets restent naturellement sensibles :

- dependance au backend local pour les demos
- besoin d'une bonne configuration MySQL
- preparation production encore partielle
- certaines fonctionnalites existent plus au niveau schema et structure qu'au niveau produit final complet

Pour une soutenance, ce n'est pas un defaut si cela est explique clairement : il faut distinguer ce qui est deja operationnel de ce qui est prepare pour les evolutions futures.
