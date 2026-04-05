# Analyse de l'existant, Besoins et Conception

---

## CHAPITRE 1 - Analyse de l'existant et etude des besoins

### 1.1 Contexte du projet

MoroccoCheck s'inscrit dans le domaine du tourisme numerique et de la geolocalisation appliquee a la verification communautaire des informations touristiques. D'apres le depot, la solution prend la forme d'une plateforme fullstack composee d'un backend Node.js / Express, d'une application utilisateur Flutter et d'une interface web d'administration React / Vite. L'objectif central est de centraliser la consultation des sites touristiques, la contribution communautaire, la verification sur place via GPS et la moderation des contenus au sein d'un meme ecosysteme.

Le probleme concret traite par le projet est clairement exprime dans les documents du depot et confirme par la logique metier du code. Les touristes et residents disposent souvent d'informations dispersees, incompletes ou obsoletes sur les lieux a visiter. Le projet cherche donc a fiabiliser cette information en combinant plusieurs mecanismes : publication d'avis, check-ins geolocalises, calcul de fraicheur des donnees, badges, classement, moderation et gestion de roles differencies. Les routes `/api/checkins`, `/api/reviews`, `/api/users/me/stats` et `/api/admin/*` montrent que la plateforme ne se limite pas a l'affichage d'un catalogue, mais orchestre un cycle complet de verification, de contribution et de controle.

Les utilisateurs cibles identifies dans le code sont les touristes, les contributeurs, les professionnels et les administrateurs. Les touristes consultent les fiches de lieux, publient des avis et suivent leur progression. Les contributeurs realisent des check-ins terrain et renforcent la valeur communautaire des donnees. Les professionnels gerent leurs etablissements, revendiquent des fiches et suivent la moderation. Les administrateurs pilotent les statistiques globales, moderent les sites et les avis, et traitent les demandes de passage du role `TOURIST` vers `CONTRIBUTOR`. La pertinence du projet est donc forte a l'heure actuelle, car il repond simultanement aux besoins d'information fiable, de confiance, de participation communautaire et de supervision des contenus.

### 1.2 Etude de l'existant

#### 1.2.1 Solutions existantes

| Solution | Description | Fonctionnalites cles | Avantages |
|----------|-------------|---------------------|-----------|
| TripAdvisor | Plateforme mondiale de recommandations touristiques basee sur les avis d'utilisateurs. | Avis, notes, photos, classement de lieux, fiches d'etablissements. | Base d'utilisateurs importante, notoriete internationale, richesse du contenu. |
| Google Maps | Service cartographique et de navigation avec fiches de lieux, horaires et avis. | Cartographie, itineraire, geolocalisation, avis, photos, informations pratiques. | Couverture geographique tres large, integration native de la navigation, ergonomie mature. |
| Booking.com | Plateforme de reservation avec forte composante d'avis et de notation des hebergements. | Reservation, avis verifies, filtres, classement, fiches detaillees. | Avis relies a une reservation, forte credibilite sur l'hebergement, moteur de recherche puissant. |
| Culture Trip | Plateforme de contenu touristique melant recommandations editoriales et suggestions de destinations. | Guides de voyage, selections editoriales, contenus thematiques. | Qualite editoriale, parcours de lecture inspire par le voyage, mise en avant d'itineraires. |
| Yelp | Plateforme communautaire de notation d'etablissements, surtout orientee restauration et services. | Avis, notes, recherche locale, photos, categories. | Dimension communautaire forte, mise en avant du retour d'experience utilisateur. |

#### 1.2.2 Critique de l'existant

Les solutions existantes couvrent efficacement la recherche d'un lieu, la consultation d'avis ou la navigation. Toutefois, elles ne repondent pas integralement au positionnement observe dans MoroccoCheck. Le code met en avant une logique de verification sur place avec contraintes GPS, rayon de validation variable, precision minimale, gestion des photos de preuve et synchronisation hors ligne. Cet axe de fiabilisation n'apparait pas comme une brique centrale dans les plateformes generalistes citees ci-dessus.

Par ailleurs, MoroccoCheck ne vise pas seulement la consultation d'informations, mais la constitution d'une communaute locale et moderee autour du tourisme marocain. Les services existants proposent des avis et des cartes, mais integrent rarement dans un meme produit un systeme de progression utilisateur, des badges, un leaderboard, un espace professionnel de revendication de site et un back-office de moderation dedie. Le developpement d'une solution specifique est donc justifie par le besoin d'unifier verification terrain, participation communautaire, moderation et pilotage metier dans un contexte touristique cible.

### 1.3 Specification des besoins

#### 1.3.1 Besoins fonctionnels

- BF01 - Le systeme doit permettre a un visiteur de creer un compte via email et mot de passe.
- BF02 - Le systeme doit permettre a un utilisateur de se connecter via email / mot de passe et, lorsque la configuration est disponible, via Google Sign-In.
- BF03 - Le systeme doit permettre a un utilisateur authentifie de consulter et mettre a jour son profil, y compris son mot de passe.
- BF04 - Le systeme doit permettre a tout utilisateur de consulter la liste des sites touristiques avec recherche, filtres, tri, carte et detail.
- BF05 - Le systeme doit permettre a un utilisateur authentifie et autorise de realiser un check-in GPS sur un site.
- BF06 - Le systeme doit permettre a un utilisateur authentifie de publier, modifier ou supprimer un avis sur un site.
- BF07 - Le systeme doit permettre a un professionnel de revendiquer un site non attribue et de gerer ses etablissements.
- BF08 - Le systeme doit permettre a un professionnel de creer et de modifier une fiche de site.
- BF09 - Le systeme doit permettre a un proprietaire de publier une reponse a un avis.
- BF10 - Le systeme doit permettre a un utilisateur de consulter ses statistiques, ses badges, son classement et son historique d'activite.
- BF11 - Le systeme doit permettre a un touriste de soumettre une demande de passage au role `CONTRIBUTOR`.
- BF12 - Le systeme doit permettre a un administrateur de consulter les statistiques globales de la plateforme.
- BF13 - Le systeme doit permettre a un administrateur de moderer les sites en attente de validation.
- BF14 - Le systeme doit permettre a un administrateur de moderer les avis et leurs photos.
- BF15 - Le systeme doit permettre a un administrateur de consulter les utilisateurs et de modifier leur role ou leur statut.
- BF16 - Le systeme doit permettre au systeme de maintenir des sessions actives, de renouveler les jetons et d'invalider une session lors de la deconnexion.

#### 1.3.2 Besoins non fonctionnels

- BNF01 - Performance : le systeme doit offrir des temps de reponse compatibles avec un usage mobile, grace a la pagination, aux index SQL, aux vues de synthese et a la separation des couches.
- BNF02 - Securite : le systeme doit proteger l'acces aux ressources via JWT, sessions en base, verification des roles, hachage des mots de passe, Helmet, CORS configurable et validation des donnees entrantes.
- BNF03 - Fiabilite des donnees : le systeme doit renforcer la credibilite des check-ins par verification GPS, controle de precision, detection de position simulee et contraintes sur la distance au site.
- BNF04 - Maintenabilite : le code doit rester evolutif grace a une architecture en couches cote backend, a l'usage de Provider et GoRouter cote Flutter, et a une separation de l'administration web.
- BNF05 - Compatibilite : la solution doit fonctionner sur plusieurs contextes d'execution, notamment Flutter Android, iOS, web et desktop, ainsi que React sur navigateur moderne.
- BNF06 - Observabilite : la plateforme doit pouvoir etre surveillee via Sentry, des endpoints `/api/health` et une journalisation backend.
- BNF07 - Scalabilite : la solution doit pouvoir evoluer avec un cache Redis pour le rate limiting, une base MySQL, un back-office separe et des pipelines CI.
- BNF08 - Experience utilisateur : l'application mobile doit prendre en charge la biometrie optionnelle, les notifications locales, la synchronisation differee et une interface adaptee aux usages de terrain.

### 1.4 Conclusion

L'analyse de l'existant et des besoins montre que MoroccoCheck depasse le cadre d'une simple application de consultation touristique. Le projet articule un catalogue de lieux, une verification terrain par geolocalisation, des mecanismes communautaires, un espace professionnel et une administration de moderation. Les besoins fonctionnels et non fonctionnels identifies mettent en evidence la necessite d'une architecture rigoureuse, capable de supporter des parcours utilisateurs differencies tout en garantissant la fiabilite des donnees. Le chapitre suivant detaille donc la conception de la solution retenue.

---

## CHAPITRE 2 - Conception de la solution

### 2.1 Architecture globale

L'architecture reelle du projet est une architecture client-serveur en trois sous-systemes complementaires. Le backend `back-end/` constitue le noyau central. Il expose une API REST construite avec Express 5 et organisee selon une separation routes -> controllers -> services -> utils / middleware / config. La couche mobile `front-end/` est developpee avec Flutter et s'appuie sur Provider pour l'etat applicatif, GoRouter pour la navigation et Dio pour les appels HTTP. Enfin, `admin-web/` est une interface web d'administration en React 18 et Vite, reservee aux comptes `ADMIN`.

Le pattern choisi peut etre decrit comme un monolithe modulaire cote serveur, complete par deux clients specialises. Le backend centralise toute la logique metier sensible : authentification, sessions, controle des roles, check-ins, avis, moderation, badges, statistiques et gestion des sites. Les routes Express definissent les points d'entree HTTP ; les controllers adaptent la requete a la logique metier ; les services encapsulent les acces base de donnees et les regles fonctionnelles ; les middlewares gerent securite, erreurs, rate limiting et uploads. Ce decoupage favorise la lisibilite et la testabilite.

La communication entre les couches suit un schema simple et robuste. L'application Flutter consomme les endpoints REST du backend via `ApiService` et des providers metier tels que `AuthProvider`, `SitesProvider` et `MapProvider`. L'application admin React se connecte a la meme API avec un client dedie et orchestre les parcours de moderation. Le backend dialogue ensuite avec MySQL, qui conserve les entites metier, les sessions, les avis, les check-ins, les photos, les badges et les structures de moderation. Des integrations complementaires sont visibles dans le code : Firebase / Google pour l'authentification federée, Sentry pour la supervision et Redis comme option de stockage pour le rate limiting.

Une description textuelle du schema d'architecture globale peut etre formulee ainsi : un utilisateur mobile ou web interagit avec l'interface Flutter, tandis qu'un administrateur utilise l'interface React ; les deux clients envoient leurs requetes HTTP a l'API Express ; le backend applique les middlewares de securite, appelle les services metier, interroge la base MySQL et retourne une reponse JSON ; des services transverses comme Sentry, Firebase Auth et Redis completent l'ecosysteme. Le systeme suit donc une architecture centralisee, modulaire et orientee services metier.

### 2.2 Modelisation UML

#### 2.2.1 Diagramme de cas d'utilisation

Acteurs :
- Visiteur
- Touriste authentifie
- Contributeur
- Professionnel
- Administrateur
- Systeme externe Google / Firebase

Cas d'utilisation :
- UC01 - Visiteur : Consulter la carte des lieux -> Afficher les sites d'Agadir sur une carte interactive avec marqueurs et informations resumées.
- UC02 - Visiteur : Parcourir la liste des sites -> Rechercher, filtrer et trier les lieux touristiques.
- UC03 - Visiteur : Consulter une fiche de site -> Lire les details, les photos, les horaires, les avis et les informations de contact.
- UC04 - Visiteur : Creer un compte -> Renseigner les informations d'identite, le mot de passe et creer un profil.
- UC05 - Touriste authentifie : Se connecter -> Ouvrir une session via email / mot de passe.
- UC06 - Touriste authentifie : Se connecter avec Google -> Obtenir un idToken Firebase puis l'echanger contre une session applicative.
- UC07 - Touriste authentifie : Modifier son profil -> Mettre a jour ses informations personnelles et son avatar.
- UC08 - Touriste authentifie : Changer son mot de passe -> Mettre a jour ses identifiants de connexion.
- UC09 - Touriste authentifie : Ajouter un avis -> Evaluer un site, saisir un commentaire et eventuellement joindre des photos.
- UC10 - Contributeur : Realiser un check-in -> Valider sa presence sur place via geolocalisation.
- UC11 - Touriste authentifie : Consulter sa progression -> Voir points, niveau, badges, classement, check-ins et avis.
- UC12 - Touriste authentifie : Demander le role contributor -> Soumettre une motivation a l'administration.
- UC13 - Professionnel : Revendiquer un site -> Associer un lieu existant a son compte professionnel.
- UC14 - Professionnel : Gerer ses etablissements -> Creer, modifier et suivre ses fiches de sites.
- UC15 - Professionnel : Repondre a un avis -> Publier une reponse proprietaire sur un avis visible.
- UC16 - Administrateur : Consulter les statistiques globales -> Visualiser l'etat de la plateforme et les files d'attente.
- UC17 - Administrateur : Moderer un site -> Approuver, rejeter ou archiver une fiche.
- UC18 - Administrateur : Moderer un avis -> Publier, rejeter, signaler ou supprimer des photos litigieuses.
- UC19 - Administrateur : Gerer les comptes -> Consulter les utilisateurs, changer role et statut.
- UC20 - Administrateur : Traiter les demandes contributor -> Approuver ou rejeter une demande.

Relations include / extend :
- UC06 inclut l'authentification Firebase / Google et l'echange du jeton avec le backend.
- UC10 inclut la verification GPS, le controle de precision et la validation du rayon autorise.
- UC14 inclut UC13 lorsque le professionnel doit d'abord revendiquer un lieu existant.
- UC17 et UC18 incluent la consignation des notes de moderation et la mise a jour des statuts.

#### 2.2.2 Diagramme de classes

```text
Classe User { id, first_name, last_name, email, role, status, points, level, rank, profile_picture, checkins_count, reviews_count }
Classe Category { id, name, name_ar, description, parent_id, color, is_active }
Classe TouristSite { id, name, description, category_id, subcategory, latitude, longitude, city, region, average_rating, freshness_score, owner_id, status, verification_status }
Classe OpeningHour { id, site_id, day_of_week, opens_at, closes_at, is_closed, is_24_hours }
Classe Checkin { id, user_id, site_id, status, latitude, longitude, accuracy, distance, validation_status, points_earned, device_info }
Classe Review { id, user_id, site_id, overall_rating, title, content, visit_date, moderation_status, owner_response, points_earned }
Classe Badge { id, name, description, type, category, rarity, required_checkins, required_reviews, required_level, points_reward }
Classe UserBadge { id, user_id, badge_id, earned_at, progress }
Classe ContributorRequest { id, user_id, requested_role, status, motivation, reviewed_by }
Classe Photo { id, user_id, entity_type, entity_id, url, thumbnail_url, moderation_status, is_primary }
Classe Favorite { id, user_id, site_id }
Classe Session { id, user_id, access_token, refresh_token, device_type, ip_address, expires_at, is_active }

Classe AuthService { registerUser(), loginUser(), loginWithGoogleToken(), refreshSession(), logoutSession(), getProfileById(), updateProfileById() }
Classe SiteService { listSites(), listMySites(), getSiteById(), createSite(), updateSite(), claimSite() }
Classe CheckinService { createCheckin(), listCheckins(), getCheckinById() }
Classe ReviewService { createReview(), listReviews(), getReviewById(), updateReview(), deleteReview(), respondToReview() }
Classe UserService { getMyStats(), getMyBadges(), getLeaderboard(), createContributorRequest(), updateMyPassword() }
Classe AdminService { getAdminStats(), getPendingSites(), reviewSite(), getPendingReviews(), moderateReview(), getUsers(), updateUserRole(), updateUserStatus(), reviewContributorRequest() }

Category "1" --> "*" Category : parent / enfant
Category "1" --> "*" TouristSite : categorise
User "1" --> "*" TouristSite : possede
User "1" --> "*" Checkin : effectue
User "1" --> "*" Review : redige
User "1" --> "*" ContributorRequest : soumet
User "1" --> "*" Session : ouvre
User "1" --> "*" UserBadge : obtient
User "1" --> "*" Favorite : enregistre
TouristSite "1" --> "*" OpeningHour : dispose de
TouristSite "1" --> "*" Checkin : recoit
TouristSite "1" --> "*" Review : recoit
Badge "1" --> "*" UserBadge : est attribue
AuthService ..> User
SiteService ..> TouristSite
CheckinService ..> Checkin
ReviewService ..> Review
UserService ..> Badge
AdminService ..> User
```

#### 2.2.3 Diagrammes de sequence

##### Scenario 1 : Authentification utilisateur par email

```text
Utilisateur -> Frontend Flutter : saisit email + mot de passe
Frontend Flutter -> AuthProvider : login(email, password)
AuthProvider -> AuthRepositoryImpl : login()
AuthRepositoryImpl -> AuthRemoteDatasource : POST /api/auth/login
AuthRemoteDatasource -> Backend Express : requete HTTP
Backend Express -> AuthController : login()
AuthController -> AuthService : loginUser()
AuthService -> MySQL : SELECT user by email
AuthService -> PasswordUtils : verifyPassword()
AuthService -> JwtUtils : generateToken()
AuthService -> MySQL : INSERT session
Backend Express -> Frontend Flutter : access_token + refresh_token + user
Frontend Flutter -> StorageService : sauvegarde token et utilisateur
Frontend Flutter -> Router : redirection vers /home ou /professional
```

##### Scenario 2 : Creation d'un check-in GPS

```text
Contributeur -> Frontend Flutter : ouvre la fiche du site et lance le check-in
Frontend Flutter -> Geolocator / MapProvider : recupere la position
Frontend Flutter -> Backend Express : POST /api/checkins avec latitude, longitude, accuracy, site_id
Backend Express -> CheckinController : createCheckinHandler()
CheckinController -> CheckinService : createCheckin()
CheckinService -> MySQL : charge le site touristique
CheckinService -> CommonService : computeDistanceFromSite()
CheckinService -> CommonService : verifie role, distance, precision, mocked location
CheckinService -> MySQL : INSERT checkin
CheckinService -> CommonService : awardPoints(), syncUserStats(), awardEligibleBadges()
Backend Express -> Frontend Flutter : confirmation du check-in
Frontend Flutter -> Profile / SitesProvider : mise a jour de l'historique et des stats
```

##### Scenario 3 : Moderation d'un avis par un administrateur

```text
Administrateur -> Admin Web : ouvre la file des avis en attente
Admin Web -> Backend Express : GET /api/admin/reviews/pending
Backend Express -> AdminController : getPendingReviews()
AdminController -> AdminService : getPendingReviews()
AdminService -> MySQL : SELECT reviews pending
Backend Express -> Admin Web : liste des avis
Administrateur -> Admin Web : choisit une decision (APPROVE / REJECT / FLAG / SPAM)
Admin Web -> Backend Express : PUT /api/admin/reviews/:id/moderate
Backend Express -> AuthMiddleware : verifie JWT et role ADMIN
Backend Express -> AdminController : moderateReviewHandler()
AdminController -> AdminService : moderateReview()
AdminService -> MySQL : UPDATE review + notes de moderation
AdminService -> MySQL : suppression eventuelle d'une photo litigieuse
Backend Express -> Admin Web : avis modere et file rafraichie
```

### 2.3 Conception de la base de donnees

#### 2.3.1 Modele conceptuel (MCD)

```text
CATEGORIES (id [PK], name, name_ar, parent_id [FK], color, is_active)
USERS (id [PK], email, password_hash, first_name, last_name, role, status, points, level, rank, profile_picture)
CONTRIBUTOR_REQUESTS (id [PK], user_id [FK], requested_role, status, motivation, reviewed_by [FK])
TOURIST_SITES (id [PK], name, category_id [FK], subcategory, latitude, longitude, city, region, owner_id [FK], status, verification_status)
OPENING_HOURS (id [PK], site_id [FK], day_of_week, opens_at, closes_at, is_closed, is_24_hours)
CHECKINS (id [PK], user_id [FK], site_id [FK], status, latitude, longitude, accuracy, distance, validation_status)
REVIEWS (id [PK], user_id [FK], site_id [FK], overall_rating, content, moderation_status, owner_response)
BADGES (id [PK], name, type, category, rarity, required_checkins, required_reviews, required_level)
USER_BADGES (id [PK], user_id [FK], badge_id [FK], earned_at, progress)
SUBSCRIPTIONS (id [PK], user_id [FK], site_id [FK], plan, billing_cycle, status)
PAYMENTS (id [PK], user_id [FK], subscription_id [FK], amount, currency, payment_method, status)
PHOTOS (id [PK], user_id [FK], entity_type, entity_id, url, thumbnail_url, moderation_status)
NOTIFICATIONS (id [PK], user_id [FK], type, title, is_read, priority)
FAVORITES (id [PK], user_id [FK], site_id [FK])
SESSIONS (id [PK], user_id [FK], access_token, refresh_token, device_type, expires_at, is_active)
```

Associations principales :
- CATEGORIES (1,n) --parent/enfant-- (0,1) CATEGORIES
- CATEGORIES (1,n) --classifie-- (1,1) TOURIST_SITES
- USERS (1,n) --soumet-- (1,1) CONTRIBUTOR_REQUESTS
- USERS (1,n) --possede-- (0,1) TOURIST_SITES
- TOURIST_SITES (1,n) --dispose de-- (1,1) OPENING_HOURS
- USERS (1,n) --effectue-- (1,1) CHECKINS
- TOURIST_SITES (1,n) --recoit-- (1,1) CHECKINS
- USERS (1,n) --redige-- (1,1) REVIEWS
- TOURIST_SITES (1,n) --recoit-- (1,1) REVIEWS
- USERS (1,n) --obtient-- (1,1) USER_BADGES
- BADGES (1,n) --attribue a-- (1,1) USER_BADGES
- USERS (1,n) --ouvre-- (1,1) SESSIONS
- USERS (1,n) --favorise-- (1,1) FAVORITES
- TOURIST_SITES (1,n) --est favori de-- (1,1) FAVORITES

#### 2.3.2 Modele logique (MLD)

```text
CATEGORIES([PK] id, name, name_ar, description, description_ar, icon, color, #parent_id [FK -> CATEGORIES.id], display_order, is_active, created_at, updated_at)
USERS([PK] id, email, password_hash, first_name, last_name, phone_number, date_of_birth, gender, nationality, profile_picture, bio, role, status, is_email_verified, is_phone_verified, email_verification_token, email_verification_expires_at, points, level, experience_points, rank, checkins_count, reviews_count, photos_count, google_id, facebook_id, apple_id, last_login_at, last_seen_at, created_at, updated_at, deleted_at)
CONTRIBUTOR_REQUESTS([PK] id, #user_id [FK -> USERS.id], requested_role, status, motivation, admin_notes, #reviewed_by [FK -> USERS.id], reviewed_at, created_at, updated_at)
TOURIST_SITES([PK] id, name, name_ar, description, description_ar, #category_id [FK -> CATEGORIES.id], subcategory, latitude, longitude, address, city, region, postal_code, country, phone_number, email, website, social_media, price_range, accepts_card_payment, has_wifi, has_parking, is_accessible, amenities, average_rating, total_reviews, freshness_score, freshness_status, last_verified_at, last_updated_at, cover_photo, #owner_id [FK -> USERS.id], is_professional_claimed, subscription_plan, status, verification_status, moderation_notes, #moderated_by [FK -> USERS.id], moderated_at, is_active, is_featured, views_count, favorites_count, created_at, updated_at, deleted_at)
OPENING_HOURS([PK] id, #site_id [FK -> TOURIST_SITES.id], day_of_week, opens_at, closes_at, is_closed, is_24_hours, notes, created_at, updated_at)
CHECKINS([PK] id, #user_id [FK -> USERS.id], #site_id [FK -> TOURIST_SITES.id], status, comment, verification_notes, latitude, longitude, accuracy, distance, is_location_verified, has_photo, points_earned, validation_status, #validated_by [FK -> USERS.id], validated_at, rejection_reason, device_info, ip_address, created_at, updated_at)
REVIEWS([PK] id, #user_id [FK -> USERS.id], #site_id [FK -> TOURIST_SITES.id], overall_rating, service_rating, cleanliness_rating, value_rating, location_rating, title, content, visit_date, visit_type, recommendations, helpful_count, not_helpful_count, reports_count, status, moderation_status, #moderated_by [FK -> USERS.id], moderated_at, moderation_notes, has_owner_response, owner_response, owner_response_date, points_earned, created_at, updated_at, deleted_at)
BADGES([PK] id, name, name_ar, description, description_ar, icon, color, type, category, rarity, required_checkins, required_reviews, required_photos, required_points, required_level, specific_conditions, points_reward, special_perks, is_active, display_order, total_awarded, created_at, updated_at)
USER_BADGES([PK] id, #user_id [FK -> USERS.id], #badge_id [FK -> BADGES.id], earned_at, progress, is_displayed, notification_sent)
SUBSCRIPTIONS([PK] id, #user_id [FK -> USERS.id], #site_id [FK -> TOURIST_SITES.id], plan, billing_cycle, amount, starts_at, ends_at, auto_renew, status, payment_provider, external_subscription_id, created_at, updated_at)
PAYMENTS([PK] id, #user_id [FK -> USERS.id], #subscription_id [FK -> SUBSCRIPTIONS.id], amount, currency, payment_method, transaction_id, provider_reference, status, paid_at, failure_reason, created_at, updated_at)
PHOTOS([PK] id, #user_id [FK -> USERS.id], entity_type, entity_id, url, thumbnail_url, caption, alt_text, width, height, file_size, mime_type, status, moderation_status, is_primary, display_order, metadata, created_at, updated_at, deleted_at)
NOTIFICATIONS([PK] id, #user_id [FK -> USERS.id], type, title, body, data, is_read, read_at, priority, created_at, updated_at)
FAVORITES([PK] id, #user_id [FK -> USERS.id], #site_id [FK -> TOURIST_SITES.id], created_at)
SESSIONS([PK] id, #user_id [FK -> USERS.id], access_token, refresh_token, device_type, device_name, device_id, os_version, app_version, ip_address, user_agent, country, city, is_active, last_activity_at, expires_at, created_at, updated_at)
```

### 2.4 Conclusion

La conception de MoroccoCheck repose sur une architecture client-serveur modulaire, une API REST fortement structuree et une base de donnees relationnelle riche en contraintes metier. Les choix de conception observent un equilibre entre experience utilisateur, fiabilite des donnees et gouvernance des contenus. La modelisation met en evidence un noyau de relations stable autour des utilisateurs, des sites, des check-ins, des avis et de la moderation. Cette base prepare naturellement la phase de realisation, qui detaille les technologies, la structure du projet et l'implementation concrete des fonctionnalites majeures.
