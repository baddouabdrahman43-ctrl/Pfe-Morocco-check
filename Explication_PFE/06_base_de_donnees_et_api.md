# 06 - Base De Donnees Et API

## 1. Choix de la base

Le projet utilise MySQL comme base relationnelle principale.

Ce choix est coherent avec le besoin de gerer :

- utilisateurs
- roles
- sites touristiques
- check-ins
- avis
- badges
- sessions
- demandes contributor

## 2. Schema visible dans les scripts SQL

Le dossier `back-end/sql/` contient plusieurs scripts de creation de schema.

Tables principales visibles :

- `categories`
- `users`
- `contributor_requests`
- `tourist_sites`
- `opening_hours`
- `checkins`
- `reviews`
- `badges`
- `user_badges`
- `sessions`

Tables additionnelles preparees :

- `subscriptions`
- `payments`
- `photos`
- `notifications`
- `favorites`

## 3. Lecture fonctionnelle des tables

### `users`

Stocke les comptes de la plateforme :

- identite
- email
- mot de passe ou mecanisme lie a l'auth
- role
- statut
- progression eventuelle

### `tourist_sites`

Stocke les fiches des lieux touristiques.

On y attend des champs comme :

- nom
- description
- categorie
- ville / region
- coordonnees GPS
- statut de publication
- relation eventuelle avec un professionnel

### `categories`

Permet de structurer les types de lieux.

### `checkins`

Enregistre la visite terrain d'un utilisateur sur un site avec des elements comme :

- utilisateur
- site
- latitude / longitude
- precision
- statut ou validation

### `reviews`

Contient les avis utilisateurs sur les sites :

- note
- titre
- contenu
- moderation
- publication
- reponse proprietaire

### `badges` et `user_badges`

Supportent la dimension gamification du projet.

### `contributor_requests`

Permet de tracer les demandes de passage au role `CONTRIBUTOR`.

### `sessions`

Permet de conserver une trace ou une logique de session cote backend.

## 4. Relations metier importantes

Quelques relations evidentes peuvent etre expliquees ainsi :

- une categorie contient plusieurs sites
- un utilisateur peut avoir plusieurs check-ins
- un utilisateur peut publier plusieurs avis
- un site peut recevoir plusieurs avis
- un site peut recevoir plusieurs check-ins
- un utilisateur peut posseder plusieurs badges
- un utilisateur peut faire une demande contributor

## 5. Triggers et automatisation SQL

Le projet contient des triggers SQL, ce qui est un point interessant pour un PFE.

Triggers visibles :

- apres insertion de check-in
- apres suppression de check-in
- avant insertion de check-in
- apres insertion de review
- apres mise a jour de review
- apres suppression de review
- avant insertion de review
- apres insertion de favorite
- apres suppression de favorite

Interpretation fonctionnelle probable :

- recalcul de statistiques
- controle de coherence
- mise a jour de compteurs
- verification de regles metier

Il faut rester prudent en soutenance : si on ne detaille pas chaque trigger dans le code, on peut expliquer qu'ils servent a automatiser certaines mises a jour et a renforcer l'integrite metier.

## 6. Contrat de reponse API

Le front documente un format de reponse attendu assez propre.

### Reponse de succes

```json
{
  "success": true,
  "data": {},
  "message": "..."
}
```

### Reponse paginee

```json
{
  "success": true,
  "data": [],
  "meta": {
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 3
    }
  }
}
```

### Reponse d'erreur

```json
{
  "success": false,
  "message": "..."
}
```

Cette normalisation facilite le travail du mobile et de l'admin web.

## 7. Principaux groupes d'endpoints

### Health

- etat du serveur
- etat base de donnees
- etat systeme

### Auth

- inscription
- connexion
- Google login
- refresh
- profil
- logout

### Sites

- liste
- detail
- photos
- reviews associes
- espace professionnel

### Check-ins

- creation
- consultation
- historique

### Reviews

- publication
- mise a jour
- suppression
- reponse proprietaire

### Profil et progression

- statistiques
- badges
- leaderboard
- demande contributor

### Admin

- stats globales
- moderation sites
- moderation reviews
- users
- contributor requests

## 8. Interet de l'API dans l'architecture

L'API est l'element de mutualisation du projet :

- le mobile et l'admin ne parlent pas directement a la base
- toute la logique passe par le backend
- la securite est centralisee
- la maintenance est plus propre

## 9. Comment presenter la base de donnees en PFE

Une bonne approche est de distinguer :

- le noyau fonctionnel deja exploite par l'application
- les tables d'evolution preparees pour des extensions futures

Le noyau fonctionnel actuel repose surtout sur :

- users
- tourist_sites
- categories
- checkins
- reviews
- badges
- user_badges
- contributor_requests
- sessions

## 10. Message important pour le jury

Le schema SQL montre que le projet a ete pense comme une plateforme evolutive et non comme une simple demo a ecran unique. Meme si toutes les tables ne sont pas exploitees au meme niveau dans l'interface, la modelisation metier est deja riche et credibilise le projet.
