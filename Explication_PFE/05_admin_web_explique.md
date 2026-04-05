# 05 - Admin Web Explique

## 1. Role de l'application admin

Le dossier `admin-web/` contient l'interface web reservee aux administrateurs.

Cette application n'est pas publique. Son but est de fournir une console de pilotage pour :

- suivre les files d'attente
- moderer les sites
- moderer les avis
- gerer les utilisateurs
- traiter les demandes contributor

## 2. Pourquoi une application admin separee

Le choix d'une application admin distincte est pertinent :

- l'interface d'administration reste separee du mobile
- la logique de moderation n'encombre pas l'experience utilisateur normale
- les administrateurs ont un outil specialise
- la securite et les routes peuvent etre mieux cloisonnees

## 3. Stack technique

L'admin web utilise :

- React 18
- Vite
- React Router
- Firebase pour le login Google admin

## 4. Point d'entree et structure

Le composant principal est `admin-web/src/App.jsx`.

Cette application gere :

- l'etat de session admin
- la redirection vers login ou dashboard
- le chargement des statistiques
- la navigation entre modules de moderation

## 5. Authentification admin

Le login admin est gere via :

- email / mot de passe
- Google Sign-In si configure

Le code verifie explicitement que l'utilisateur connecte a bien le role `ADMIN`.

Cela signifie qu'un utilisateur connecte sans role admin ne peut pas utiliser la console.

## 6. Gestion de session

Le fichier `src/lib/api.js` montre une gestion locale de session avec :

- stockage du token
- stockage des infos utilisateur
- emission d'evenements de session
- suppression de session si token expire

C'est une logique simple mais efficace pour une SPA admin.

## 7. Routes principales de l'admin

Routes UI :

- `/login`
- `/dashboard/overview`
- `/dashboard/sites`
- `/dashboard/sites/:siteId`
- `/dashboard/reviews`
- `/dashboard/reviews/:reviewId`
- `/dashboard/contributor-requests`
- `/dashboard/users`
- `/dashboard/users/:userId`

Cette navigation couvre les besoins critiques d'un back-office de moderation.

## 8. Dashboard et donnees chargees

Le dashboard charge plusieurs blocs de donnees en parallele :

- statistiques globales
- sites en attente
- avis en attente
- demandes contributor
- liste des utilisateurs

Cette organisation permet a l'admin d'avoir une vue d'ensemble immediate.

## 9. Moderation des sites

L'admin peut consulter les sites en attente puis appliquer des decisions comme :

- `APPROVE`
- `REJECT`
- `ARCHIVE`

Cela structure un vrai workflow editorial.

## 10. Moderation des avis

L'admin peut consulter les avis en attente et choisir par exemple :

- `APPROVE`
- `REJECT`
- `FLAG`
- `SPAM`

Le projet prend donc au serieux la qualite du contenu affiche.

## 11. Gestion des demandes contributor

Les demandes de changement de role sont centralisees dans une file dediee.

Actions principales :

- approuver
- rejeter

Ce point relie bien la logique communautaire du mobile avec la logique de controle admin.

## 12. Gestion des utilisateurs

L'admin peut :

- filtrer les utilisateurs
- consulter leur detail
- modifier leur role
- modifier leur statut

Les statuts disponibles visibles dans le code incluent :

- `ACTIVE`
- `SUSPENDED`
- `INACTIVE`

## 13. Client API admin

`src/lib/api.js` centralise tous les appels reseau.

Fonctions importantes :

- `login`
- `loginWithGoogle`
- `fetchAdminStats`
- `fetchPendingSites`
- `moderateSite`
- `fetchPendingReviews`
- `moderateReview`
- `fetchContributorRequests`
- `reviewContributorRequest`
- `fetchUsers`
- `fetchUserById`
- `updateUserRole`
- `updateUserStatus`

Ce choix simplifie la maintenance de l'application admin.

## 14. Forces de l'admin web

- vraie separation des responsabilites
- interface centree sur la moderation
- filtres et files d'attente
- verification stricte du role admin
- branchement direct sur les endpoints dedies du backend

## 15. Limites ou evolutions possibles

Le README du projet rappelle que certaines extensions sont encore possibles :

- categories admin plus riches
- badges admin
- analytics avances
- securisation d'exploitation production plus complete

## 16. Comment presenter l'admin web en soutenance

Une formulation simple et forte :

- l'admin web complete l'application mobile
- il apporte la dimension de gouvernance du contenu
- il permet la moderation, la supervision et la gestion des comptes
- il rend le projet plus realiste qu'une application communautaire sans controle
