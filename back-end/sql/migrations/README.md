# SQL Migrations

Ce dossier contient les migrations incrementales appliquees par:

```bash
npm run migrate
```

Regles de nommage recommandees:

- `YYYYMMDDHHMM_description.sql`

Exemple:

- `202603271100_add_review_reports_index.sql`

Le runner:

- cree automatiquement la table `schema_migrations`
- applique les fichiers `.sql` dans l ordre alphabetique
- ignore les migrations deja enregistrees
- expose aussi `npm run migrate:status`

Le schema historique complet reste disponible dans `back-end/sql/` via:

- `install_database.sql`
- `create_tables*.sql`
- `create_views.sql`
- `create_triggers.sql`

Pour une nouvelle instance:

1. initialiser la base avec `install_database.sql`
2. lancer ensuite `npm run migrate`
