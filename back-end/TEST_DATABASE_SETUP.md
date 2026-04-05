# Test Database Setup

Ce guide prepare une vraie base MySQL pour valider les tests backend de MoroccoCheck.

## 1. Creer le fichier d environnement de test

Copier `back-end/.env.test.example` vers `back-end/.env.test`, puis ajuster les identifiants MySQL si necessaire.

## 2. Creer la base de test

Executer les scripts SQL sur une base dediee, par exemple `moroccocheck_test`.

Exemple:

```bash
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS moroccocheck_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p moroccocheck_test < sql/install_database.sql
```

## 3. Verifier la configuration

Le backend charge automatiquement `.env.test` quand `NODE_ENV=test`.

Points a verifier:

- `DB_NAME=moroccocheck_test`
- `DB_EXIT_ON_FAILURE=false`
- le schema contient bien `users`, `tourist_sites`, `reviews`, `checkins`, `categories`

## 4. Lancer les tests

```bash
npm test
```

## 5. Resultat attendu

Si la base de test est disponible, les suites backend ne doivent plus etre en `pending` a cause de l absence de base ou de schema.
