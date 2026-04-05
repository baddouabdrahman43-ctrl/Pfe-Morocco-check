# MoroccoCheck

MoroccoCheck est une plateforme touristique communautaire composee de trois applications:

- `back-end`: API Node.js / Express connectee a MySQL
- `front-end`: application Flutter pour les utilisateurs
- `admin-web`: interface React/Vite pour les comptes `ADMIN`

Le projet permet de consulter des sites touristiques, publier des avis, effectuer des check-ins GPS, suivre une progression utilisateur et moderer les contenus via une interface d administration.

## Structure Du Depot

```text
App_Touriste/
|- back-end/
|- front-end/
|- admin-web/
|- use_cases/
|- PLAN_LIVRAISON_SPRINTS.md
|- RAPPORT_DETAILLE_APPLICATION.md
```

## Demarrage Rapide

### 1. Backend

```bash
cd back-end
npm install
npm run dev
```

API locale:

- `http://127.0.0.1:5001/api/health`

### 2. Frontend Flutter

```bash
cd front-end
flutter pub get
flutter run
```

### 3. Admin Web

```bash
cd admin-web
npm install
npm run dev
```

Interface locale:

- `http://127.0.0.1:5173`

## Configuration Locale

- le backend utilise `.env` dans `back-end/`
- l API locale attendue par defaut est `http://127.0.0.1:5001/api`
- le front Flutter utilise aussi `10.0.2.2:5001` sur emulateur Android
- l admin web peut surcharger l API via `VITE_API_BASE_URL`

## Environnements

La matrice `development / staging / production` est formalisee dans:

- [ENVIRONMENTS.md](/C:/Users/User/App_Touriste/ENVIRONMENTS.md)

Templates disponibles:

- [back-end/.env.example](/C:/Users/User/App_Touriste/back-end/.env.example)
- [front-end/.env.example](/C:/Users/User/App_Touriste/front-end/.env.example)
- [admin-web/.env.example](/C:/Users/User/App_Touriste/admin-web/.env.example)

## Scope Fonctionnel Actuel

### Utilisateur mobile

- inscription et connexion
- gestion du profil
- consultation des sites
- details d un site
- check-in GPS
- publication d avis
- badges, stats et leaderboard
- demande de passage `TOURIST -> CONTRIBUTOR`

### Professionnel

- consultation de l espace professionnel
- revendication d un site
- soumission et suivi de fiches de sites

### Administration

- connexion admin
- dashboard de stats
- moderation des sites
- moderation des avis
- gestion des utilisateurs
- traitement des demandes contributor

## Documentation De Reference

- [PLAN_LIVRAISON_SPRINTS.md](/C:/Users/User/App_Touriste/PLAN_LIVRAISON_SPRINTS.md)
- [SCOPE_V1.md](/C:/Users/User/App_Touriste/SCOPE_V1.md)
- [ROLES_ET_PERMISSIONS.md](/C:/Users/User/App_Touriste/ROLES_ET_PERMISSIONS.md)
- [FLUX_CRITIQUES_V1.md](/C:/Users/User/App_Touriste/FLUX_CRITIQUES_V1.md)
- [CHECKLIST_RECETTE_V1.md](/C:/Users/User/App_Touriste/CHECKLIST_RECETTE_V1.md)
- [BACKLOG_TICKETS_V1.md](/C:/Users/User/App_Touriste/BACKLOG_TICKETS_V1.md)
- [BOARD_SPRINT_2.md](/C:/Users/User/App_Touriste/BOARD_SPRINT_2.md)
- [back-end/README.md](/C:/Users/User/App_Touriste/back-end/README.md)
- [front-end/README.md](/C:/Users/User/App_Touriste/front-end/README.md)
- [admin-web/README.md](/C:/Users/User/App_Touriste/admin-web/README.md)

## Etat Du Sprint 1

Le Sprint 1 vise a:

- stabiliser la documentation
- clarifier le scope V1
- formaliser les roles et permissions
- lister les flux critiques a tester avant livraison
- reduire les contradictions documentaires dans le depot

## Notes

- certains documents anciens restent utiles comme historique, mais ne doivent plus etre consideres comme source de verite si leur contenu contredit les fichiers de reference ci-dessus
- la publication production n est pas encore finalisee: voir [PLAN_LIVRAISON_SPRINTS.md](/C:/Users/User/App_Touriste/PLAN_LIVRAISON_SPRINTS.md)
