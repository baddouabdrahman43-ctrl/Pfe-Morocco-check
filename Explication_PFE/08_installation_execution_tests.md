# 08 - Installation Execution Tests

## 1. Prerequis generaux

Pour faire tourner le projet en local, il faut au minimum :

- Node.js
- npm
- Flutter stable
- Android SDK pour le mobile Android
- MySQL

## 2. Lancement du backend

Depuis `back-end/` :

```bash
npm install
npm run dev
```

Le backend demarre par defaut sur :

- `http://127.0.0.1:5001`

Verification rapide :

```bash
http://127.0.0.1:5001/api/health
```

## 3. Lancement du front Flutter

Depuis `front-end/` :

```bash
flutter pub get
flutter run --flavor staging --dart-define=APP_ENV=development
```

Le front peut cibler :

- emulateur Android
- telephone Android connecte en USB
- Chrome / Edge pour tests web

## 4. Cas particulier du telephone Android physique

Sur un appareil physique, le front ne peut pas joindre le backend local avec `10.0.2.2` comme sur emulateur. Le projet et l'environnement de travail utilisent alors souvent un tunnel USB :

```bash
adb reverse tcp:5001 tcp:5001
```

Puis le front peut pointer vers :

```text
http://127.0.0.1:5001
```

Ce point est tres utile a connaitre pour une demo PFE sur vrai telephone.

## 5. Lancement de l'admin web

Depuis `admin-web/` :

```bash
npm install
npm run dev
```

Par defaut, l'admin vise :

```text
http://127.0.0.1:5001/api
```

## 6. Sequence de lancement conseillee

Ordre pratique pour une demo :

1. demarrer MySQL
2. demarrer le backend
3. verifier `/api/health`
4. lancer le mobile Flutter
5. lancer l'admin web

## 7. Configuration d'environnement

Le projet s'appuie sur plusieurs fichiers d'environnement ou templates :

- backend : `.env`
- front : `dart-define` et fichiers d'exemple
- admin : variables `VITE_*`

Exemples de variables critiques :

- base MySQL
- secret JWT
- Google client IDs
- Firebase
- URL API

## 8. Tests disponibles

### Backend

Le backend dispose de tests `Mocha`, `Chai`, `Supertest`.

Commande :

```bash
npm test
```

### Flutter

Le front dispose de tests Flutter.

Commandes :

```bash
flutter analyze
flutter test
```

### Admin web

L'admin web expose aussi des scripts utiles :

```bash
npm test
npm run lint
npm run typecheck
```

## 9. Verification fonctionnelle minimale

Pour valider le projet en demonstration, il faut idealement verifier :

1. inscription ou connexion
2. affichage de la liste des sites
3. ouverture d'un detail site
4. publication d'un avis ou check-in
5. consultation du profil
6. ouverture du dashboard admin
7. moderation d'un contenu ou traitement d'une demande

## 10. Risques pratiques en demo

Les points a anticiper sont :

- backend non lance
- MySQL non demarre
- mauvaise variable d'environnement
- probleme Firebase / Google Sign-In
- appareil Android non reconnu
- URL API invalide sur telephone reel

## 11. Conseils de preparation avant soutenance

- preparer une base de donnees deja seeded
- tester les comptes de demo a l'avance
- verifier l'appareil Android
- garder une route de secours web ou emulator
- verifier l'API health avant de commencer
- preparer un scenario de demo court et stable

## 12. Message utile pour le rapport

L'installation du projet montre qu'il s'agit d'un systeme multi-composants reel. Le deploiement local demande une coordination entre base, backend, mobile et admin web, ce qui renforce la valeur technique du travail realise.
