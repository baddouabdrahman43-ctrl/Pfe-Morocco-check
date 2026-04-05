# MoroccoCheck Admin Web

Interface web d administration reservee aux comptes `ADMIN`.

Elle est connectee au backend MoroccoCheck et permet de piloter les zones critiques du produit.

## Demarrage

```bash
cd admin-web
npm install
npm run dev
```

Par defaut, l interface appelle:

- `http://127.0.0.1:5001/api`

Pour changer l API:

```bash
set VITE_API_BASE_URL=http://127.0.0.1:5001/api
npm run dev
```

Template d environnement:

- [admin-web/.env.example](/C:/Users/User/App_Touriste/admin-web/.env.example)

Reference globale:

- [ENVIRONMENTS.md](/C:/Users/User/App_Touriste/ENVIRONMENTS.md)

## Build

```bash
npm run build
npm run build:staging
npm run build:production
```

## Fonctions Disponibles

- connexion admin
- dashboard avec stats globales
- moderation des sites
- detail d un site admin
- moderation des avis
- detail d un avis admin
- consultation des utilisateurs
- mise a jour du statut utilisateur
- traitement des demandes contributor
- deconnexion

## Routes UI

- `/login`
- `/dashboard/overview`
- `/dashboard/sites`
- `/dashboard/sites/:siteId`
- `/dashboard/reviews`
- `/dashboard/reviews/:reviewId`
- `/dashboard/contributor-requests`
- `/dashboard/users`
- `/dashboard/users/:id`

## Dependances Techniques

- React 18
- Vite
- React Router

## Verification Locale

Verifier au minimum:

1. login admin
2. chargement du dashboard
3. moderation d un site
4. moderation d un avis
5. consultation des utilisateurs
6. traitement d une demande contributor

## Note De Deploiement

L application est une SPA.

Le serveur de production doit:

- servir les assets du build
- rewriter les routes inconnues vers `index.html`
- exposer la bonne valeur de `VITE_API_BASE_URL`

## Limites Actuelles

- pas encore de modules categories admin, badges admin ou analytics avances
- la securisation d exploitation production reste a finaliser
