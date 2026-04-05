# Etat d'avancement - MoroccoCheck Frontend

Date: 26/02/2026

## Resume global
- Avancement estime: **70%**
- Etat: **MVP fonctionnel partiel**
- Priorite actuelle: finaliser les integrations API reelles, reduire les warnings, renforcer tests/documentation.

## Avancement par jalon (plan 7 jours)

### Jour 1 - Configuration & Design System
- Statut: **85%**
- Fait:
  - Architecture de base `core/`, `features/`, `shared/`
  - Theme, couleurs, styles, constantes
  - Router principal et navigation de base
  - Services `ApiService`, `StorageService`, `LocationService`
  - Widgets partages (`CustomButton`, `CustomTextField`, `LoadingIndicator`)
- Reste:
  - Nettoyage qualité (lints/warnings)

### Jour 2 - Authentification
- Statut: **80%**
- Fait:
  - `Login`, `Register`, `ForgotPassword`, `Welcome`
  - `AuthProvider` avec login/register/logout/auto-login
  - Stockage token et user local
- Reste:
  - Completer certains elements domain (ex: `user_entity` encore TODO)
  - Durcir certains flux async/context

### Jour 3 - Carte & Geolocalisation
- Statut: **75%**
- Fait:
  - Carte fonctionnelle avec geolocalisation
  - Markers et recentrage utilisateur
  - Adaptation API gratuite OpenStreetMap (`flutter_map`)
- Note:
  - Le plan initial mentionne Google Maps; implementation migree vers OSM pour cout zero.

### Jour 4 - Liste Sites & Detail
- Statut: **80%**
- Fait:
  - Liste sites, recherche, filtres categorie
  - Ecran detail avec tabs Infos/Avis/Photos
  - Navigation liste -> detail -> actions
- Reste:
  - Hero animation / polish visuel complet
  - Quelques TODO mineurs

### Jour 5 - Check-in GPS & Avis
- Statut: **60%**
- Fait:
  - UI check-in, verification distance (<100m), animation succes
  - UI ajout avis avec notation et validation
- Reste (important):
  - Envoi API reel check-in (`TODO`)
  - Envoi API reel avis (`TODO`)
  - Upload photo (image picker) non finalise

### Jour 6 - Profil & Gamification
- Statut: **65%**
- Fait:
  - Ecran profil present (stats, badges, progression)
- Reste:
  - Logique metier complete niveaux/badges via API
  - Historique dynamique reel

### Jour 7 - Finitions, tests, qualite
- Statut: **40%**
- Fait:
  - Base UI utilisable
- Reste (critique):
  - Reduction des warnings analyse statique
  - Tests unitaires/widget reels (actuellement smoke test minimal)
  - README projet a completer (architecture, setup, flux, captures)

## Blocages / dette technique
- Plusieurs warnings `flutter analyze` (prints, deprecations, async context, variables inutilisees).
- Quelques TODO encore presents sur flux metiers.
- Documentation projet insuffisante pour livraison.

## Plan court pour passer a 90%+
1. Finaliser API check-in/review + gestion erreurs utilisateur.
2. Corriger warnings prioritaires (`auth_provider`, `checkin`, `api/storage` logs).
3. Ajouter tests minimum:
   - AuthProvider
   - SitesProvider (search/filter)
   - Navigation liste/detail
4. Mettre a jour README avec:
   - prerequis
   - lancement
   - architecture
   - captures ecran

## Fichiers cibles prioritaires
- `lib/features/sites/presentation/checkin_screen.dart`
- `lib/features/sites/presentation/add_review_screen.dart`
- `lib/features/auth/domain/user_entity.dart`
- `lib/features/auth/presentation/auth_provider.dart`
- `README.md`
