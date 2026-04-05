# Guide des etapes a suivre pour completer le frontend mobile

Ce guide sert de feuille de route pour terminer proprement le frontend mobile MoroccoCheck en tenant compte de l'etat actuel du projet.

Il se concentre sur:
- les points manquants du frontend mobile;
- leur ordre de priorite;
- les dependances backend associees;
- les fichiers a toucher en premier.

Contexte actuel:
- le frontend mobile est deja branche sur le backend pour `auth`, `sites`, `detail`, `reviews`, `photos`, `check-in`, `profil`, `badges`, `stats`, `leaderboard`;
- l'application est actuellement focalisee sur `Agadir`;
- l'administration doit etre separee dans une future `web app admin`;
- ce guide concerne donc uniquement l'app mobile pour `touristes`, `visiteurs`, `contributors` et `professionals`.

---

## 1. Objectif

Finaliser le frontend mobile pour qu'il soit:
- coherent avec les roles utilisateur;
- plus robuste sur les parcours invites et connectes;
- pret pour les parcours `PROFESSIONAL`;
- plus propre en UX;
- aligne avec les vraies capacites backend.

---

## 2. Priorites globales

Ordre recommande:

1. securiser les parcours avec des gardes de navigation;
2. corriger les faux parcours visibles comme `mot de passe oublie`;
3. definir les parcours `PROFESSIONAL`;
4. enrichir le profil utilisateur;
5. transformer l'ecran Reglages en vrai ecran de preferences;
6. preparer les extensions futures comme upload photo et catalogue badges.

---

## 3. Phase 1 - Securiser les parcours utilisateur

### Objectif

Eviter qu'un visiteur ou un utilisateur non autorise accede a des ecrans ou actions reserves.

### Problemes a corriger

- le mode visiteur peut entrer dans l'app sans authentification;
- les routes `check-in`, `review`, `profile` et certains parcours proteges ne sont pas bloques avant l'appel API;
- l'utilisateur decouvre souvent trop tard qu'il n'a pas le droit.

### Etapes a suivre

1. Ajouter une logique de garde dans le routeur.
2. Definir les routes publiques:
   - `/`
   - `/welcome`
   - `/login`
   - `/register`
   - `/sites`
   - `/sites/:id`
   - `/map`
3. Definir les routes protegees:
   - `/profile`
   - `/leaderboard`
   - `/checkin/:id`
   - `/review/:id`
4. Ajouter une redirection automatique vers `/login` ou `/welcome` si l'utilisateur n'est pas connecte.
5. Cacher ou desactiver les boutons `Check-in` et `Ajouter un avis` pour les visiteurs.
6. Afficher un message clair:
   - `Connectez-vous pour effectuer un check-in`
   - `Connectez-vous pour publier un avis`

### Fichiers a traiter

- `lib/core/router/app_router.dart`
- `lib/features/auth/presentation/auth_provider.dart`
- `lib/features/auth/presentation/welcome_screen.dart`
- `lib/features/sites/presentation/site_detail_screen.dart`
- `lib/features/sites/presentation/checkin_screen.dart`
- `lib/features/sites/presentation/add_review_screen.dart`

### Resultat attendu

- un visiteur peut consulter les sites;
- un visiteur ne peut pas lancer un parcours protege;
- les erreurs `401/403` sont moins frequentes car on bloque plus tot.

---

## 4. Phase 2 - Corriger les faux parcours UX

### Objectif

Supprimer ou finaliser les ecrans qui donnent l'impression de fonctionner alors qu'ils sont encore simules.

### Cas principal: mot de passe oublie

Aujourd'hui, l'ecran affiche un succes local sans vrai appel backend.

### Etapes a suivre

1. Verifier si le backend expose une route de reset password.
2. Si la route existe:
   - ajouter l'appel API dans `ApiService`;
   - brancher le formulaire sur cette route;
   - afficher succes ou erreur reels.
3. Si la route n'existe pas:
   - masquer temporairement le lien `Mot de passe oublie`;
   - ou conserver l'ecran mais marquer clairement la fonctionnalite comme indisponible.

### Fichiers a traiter

- `lib/features/auth/presentation/login_screen.dart`
- `lib/features/auth/presentation/forgot_password_screen.dart`
- `lib/core/network/api_service.dart`

### Resultat attendu

- plus aucun faux flux critique visible dans l'app.

---

## 5. Phase 3 - Ajouter les parcours PROFESSIONAL

### Objectif

Donner une vraie utilite mobile aux utilisateurs `PROFESSIONAL`.

### Ce qui manque aujourd'hui

- creation de site;
- edition de son propre site;
- suivi de statut de validation;
- gestion des lieux soumis;
- distinction UX entre `TOURIST` et `PROFESSIONAL`.

### Etapes a suivre

1. Verifier les endpoints backend existants pour:
   - `POST /api/sites`
   - `PUT /api/sites/:id`
   - lecture des sites d'un proprietaire si disponible
2. Ajouter un detecteur de role dans le frontend:
   - si `user.role == PROFESSIONAL`, afficher des actions supplementaires.
3. Ajouter un point d'entree dans le profil ou l'accueil:
   - `Mes etablissements`
   - `Ajouter un lieu`
4. Creer un ecran `create_site_screen.dart`.
5. Creer un formulaire:
   - nom
   - categorie
   - description
   - adresse
   - ville
   - region
   - latitude
   - longitude
6. Ajouter un ecran `my_sites_screen.dart` pour voir les lieux soumis.
7. Ajouter les badges de statut:
   - `PENDING_REVIEW`
   - `PUBLISHED`
   - `REJECTED`
8. Plus tard:
   - edition d'un lieu
   - visualisation des performances

### Fichiers a creer ou modifier

- `lib/core/network/api_service.dart`
- `lib/shared/models/user.dart`
- `lib/features/profile/presentation/profile_screen.dart`
- `lib/features/home/presentation/home_screen.dart`
- `lib/features/professional/presentation/create_site_screen.dart`
- `lib/features/professional/presentation/my_sites_screen.dart`
- `lib/features/professional/models/professional_site.dart`

### Resultat attendu

- un professionnel peut utiliser l'app pour proposer et suivre ses lieux;
- le role `PROFESSIONAL` a enfin un vrai parcours mobile.

---

## 6. Phase 4 - Enrichir le profil utilisateur

### Objectif

Transformer le profil en centre de pilotage utile pour le mobile.

### Ce qui peut encore etre ajoute

- edition du profil;
- photo de profil;
- consultation du catalogue global des badges;
- meilleure mise en avant du role et du rang;
- pour un pro: acces a ses propres outils.

### Etapes a suivre

1. Ajouter un bouton `Modifier mon profil`.
2. Creer un ecran `edit_profile_screen.dart`.
3. Brancher le formulaire sur `PUT /api/auth/profile` si l'endpoint est disponible.
4. Ajouter un ecran `badges_catalog_screen.dart` base sur `GET /api/badges`.
5. Depuis le profil:
   - afficher `Mes badges`
   - afficher `Voir tous les badges`
6. Pour `PROFESSIONAL`, ajouter une section:
   - `Mes lieux`
   - `Ajouter un lieu`

### Fichiers a traiter

- `lib/features/profile/presentation/profile_screen.dart`
- `lib/core/network/api_service.dart`
- `lib/features/profile/presentation/edit_profile_screen.dart`
- `lib/features/profile/presentation/badges_catalog_screen.dart`

### Resultat attendu

- le profil n'est plus seulement consultatif;
- il devient un vrai centre utilisateur.

---

## 7. Phase 5 - Transformer Reglages en vrai ecran de preferences

### Objectif

Remplacer l'ecran informatif actuel par de vraies options utiles.

### Fonctions a ajouter

- preference de langue;
- activation/desactivation des notifications;
- choix d'affichage de la localisation;
- ouverture des parametres systeme de localisation;
- informations de version de l'app;
- lien vers politique de confidentialite;
- support / contact;
- effacement du cache local si necessaire.

### Etapes a suivre

1. Garder les infos techniques utiles mais les deplacer dans une section secondaire.
2. Ajouter des `SwitchListTile` pour les preferences locales.
3. Persister ces preferences avec `StorageService`.
4. Ajouter un bouton `Ouvrir les reglages systeme` pour la localisation.
5. Ajouter une section `A propos`.

### Fichiers a traiter

- `lib/features/settings/presentation/settings_screen.dart`
- `lib/core/storage/storage_service.dart`
- eventuellement `lib/core/location/location_service.dart`

### Resultat attendu

- l'ecran Reglages devient un vrai ecran produit;
- il n'est plus seulement un panneau de debug documente.

---

## 8. Phase 6 - Preparations pour les futures fonctions backend

### Objectif

Preparer le frontend pour les evolutions sans mentir a l'utilisateur.

### Fonction upload photo review

Etat actuel:
- clairement non disponible.

Strategie recommandee:

1. Garder le message actuel tant que le backend n'est pas pret.
2. Quand la route backend existe:
   - ajouter la selection image;
   - envoyer un multipart form-data;
   - gerer l'etat d'upload;
   - afficher l'image dans le detail review si necessaire.

### Fonction badges globaux

1. Ajouter l'appel `GET /api/badges`.
2. Afficher toutes les conditions de debloquage.

### Fonction favoris

Si le backend expose les routes:

1. ajouter `ajouter aux favoris`;
2. ajouter `retirer des favoris`;
3. afficher la liste des favoris dans le profil.

---

## 9. Phase 7 - Nettoyage UX et qualite

### Objectif

Stabiliser l'application avant d'ouvrir de nouveaux gros chantiers.

### Etapes a suivre

1. Repasser sur les textes encore trop techniques.
2. Uniformiser les messages d'erreur.
3. Verifier les retours visuels:
   - loading
   - succes
   - erreur
   - vide
4. Ajouter des tests widget sur:
   - route guard
   - ecran leaderboard
   - affichage conditionnel des boutons proteges
   - ecran forgot password
5. Tester:
   - visiteur
   - utilisateur connecte
   - contributor
   - professional

### Commandes de verification

```bash
flutter analyze
flutter test -r expanded
```

---

## 10. Plan de realisation concret

Si tu veux avancer efficacement, suis cet ordre exact:

### Semaine 1

1. ajouter les `route guards`
2. bloquer les actions reservees aux invites
3. corriger ou masquer `mot de passe oublie`

### Semaine 2

1. ajouter le catalogue badges
2. ajouter l'edition de profil
3. transformer Reglages en vrai ecran utilisateur

### Semaine 3

1. ajouter les parcours `PROFESSIONAL`
2. creer `Mes etablissements`
3. creer `Ajouter un lieu`

### Semaine 4

1. preparer l'upload photo review si le backend avance
2. ajouter les tests widget manquants
3. faire une passe complete UX/QA

---

## 11. Checklist finale

### Navigation et securite

- [ ] Les routes protegees sont redirigees si non connecte
- [ ] Les visiteurs ne voient pas les actions reservees
- [ ] Le mode visiteur reste possible pour consulter les sites

### Auth

- [ ] `forgot password` est soit reel, soit masque
- [ ] Les erreurs auth sont coherentes
- [ ] Le refresh token reste stable

### Profil

- [ ] Le profil peut etre modifie
- [ ] Les badges globaux sont visibles
- [ ] Le leaderboard est accessible

### Professional

- [ ] Un pro peut ajouter un lieu
- [ ] Un pro peut consulter ses lieux
- [ ] Les statuts des lieux sont visibles

### Reglages

- [ ] L'ecran contient de vraies preferences
- [ ] Les preferences sont sauvegardees localement

### Qualite

- [ ] `flutter analyze` passe
- [ ] `flutter test` passe
- [ ] Les parcours invites / connectes / pro sont verifies

---

## 12. Decision produit importante

Ce frontend mobile ne doit pas devenir l'interface admin.

Separation recommandee:
- `mobile app` pour `TOURIST`, `CONTRIBUTOR`, `PROFESSIONAL`
- `web admin app` pour `ADMIN` et `MODERATOR`

Le frontend mobile doit donc rester centre sur:
- consultation;
- contribution terrain;
- check-in;
- avis;
- parcours professionnel mobile.

