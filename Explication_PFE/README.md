# Explication_PFE

Ce dossier regroupe une documentation detaillee du projet `MoroccoCheck` pour un usage PFE.

Objectif du dossier :

- expliquer clairement ce que fait le projet
- decrire l'architecture reelle du depot
- detailler le backend, le front Flutter et l'admin web
- presenter les flux metier importants
- donner une base solide pour rediger un rapport ou preparer une soutenance

Ordre de lecture conseille :

1. `01_presentation_generale.md`
2. `02_architecture_globale.md`
3. `03_backend_explique.md`
4. `04_frontend_flutter_explique.md`
5. `05_admin_web_explique.md`
6. `06_base_de_donnees_et_api.md`
7. `07_flux_metier_et_parcours.md`
8. `08_installation_execution_tests.md`
9. `09_pistes_pfe_et_soutenance.md`

Resume tres court du projet :

- `back-end/` : API REST Node.js / Express connectee a MySQL
- `front-end/` : application Flutter destinee aux utilisateurs mobiles
- `admin-web/` : interface React/Vite reservee aux administrateurs

Fonctions principales du produit :

- inscription et connexion des utilisateurs
- consultation de sites touristiques
- check-in geolocalise sur site
- publication d'avis
- badges, statistiques et classement
- espace professionnel
- moderation admin des contenus et des comptes

Architecture resumee :

```text
Utilisateur mobile -> Front Flutter -> API Express -> MySQL
Administrateur web -> Admin React  -> API Express -> MySQL
```

Ce dossier ne remplace pas le code source, mais il sert de guide de lecture detaille pour comprendre rapidement le projet avant une presentation, une soutenance ou une phase de maintenance.
