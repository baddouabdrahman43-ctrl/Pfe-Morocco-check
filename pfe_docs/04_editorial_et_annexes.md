# Contenu Editorial - Pages Preliminaires, Intro, Conclusion, Annexes

---

## PAGE DE GARDE

Les informations suivantes peuvent etre reprises directement dans la page de garde LaTeX du rapport :

- Logo gauche : Universite Ibn Zohr - Agadir
- Logo droite : Ecole Superieure de Technologie d'Agadir (ESTA)
- Etablissement : Universite Ibn Zohr - Agadir
- Ecole : Ecole Superieure de Technologie d'Agadir (ESTA)
- Departement : Departement Informatique
- Mention centrale : PROJET DE FIN D'ETUDES
- Sous-titre : Pour l'obtention du diplome DUT - Conception et Developpement de Logiciel
- Theme : MoroccoCheck - Plateforme touristique communautaire verifiee par geolocalisation
- Realise par : Abderrahmane BADDOU ; Ahmed EL IDRISSI
- Encadre par : Pr. Aicha BAKKI
- Jury : Pr. Abderrahim SABOUR ; Pr. Aicha BAKKI
- Soutenu le : 30 / 03 / 2026
- Annee universitaire : 2025 / 2026

---

## DEDICACE

Nous dedicacons ce travail a nos parents, pour leurs sacrifices, leur affection et leur soutien constant tout au long de notre parcours.

Nous le dedicacons egalement a nos familles, qui nous ont toujours encourages a perseverer et a donner le meilleur de nous-memes.

Nous exprimons aussi une pensee reconnaissante a tous ceux qui ont cru en nos capacites et nous ont accompagnes durant cette periode de formation.

Enfin, nous dedicacons ce projet a toute personne qui voit dans la technologie un moyen concret de creer des solutions utiles, fiables et proches des besoins reels des utilisateurs.

---

## REMERCIEMENTS

Avant toute chose, nous rendons grace a Allah, Le Tout-Puissant, de nous avoir accorde la sante, la patience, la volonte et la perseverance necessaires pour mener a bien ce projet de fin d'etudes.

Nous adressons nos plus profonds remerciements a nos parents et a nos familles pour leur soutien moral, leurs sacrifices, leurs encouragements permanents et la confiance qu'ils nous ont accordee durant toutes nos annees d'etudes. Leur presence a constitue une source essentielle de motivation.

Nous exprimons notre sincere gratitude a notre encadrante pedagogique, Pr. Aicha BAKKI, pour la qualite de son accompagnement, ses conseils, sa disponibilite et la rigueur academique qu'elle nous a transmise tout au long de ce travail. Ses remarques et ses orientations ont largement contribue a l'amelioration de ce projet.

Nos remerciements vont egalement aux membres du jury, Pr. Abderrahim SABOUR et Pr. Aicha BAKKI, pour l'honneur qu'ils nous font en evaluant ce travail, ainsi que pour le temps consacre a son examen.

Nous remercions l'Ecole Superieure de Technologie d'Agadir, l'Universite Ibn Zohr et l'ensemble des enseignants du Departement Informatique pour la formation recue, les connaissances transmises et l'encadrement assure tout au long de notre cursus.

Le code source analyse ne fait apparaitre aucun encadrant entreprise, ce projet etant formule comme un projet academique interne. Cette remarque pourra etre ajustee manuellement si une information complementaire existe hors depot.

Nous remercions aussi nos amis, collegues et camarades de promotion pour leurs encouragements, leur entraide et les echanges enrichissants qui ont accompagne la realisation de ce travail.

Enfin, nous adressons nos remerciements a toute personne ayant contribue, de pres ou de loin, a l'aboutissement de ce projet.

---

## RESUME (Francais - 180-220 mots)

Le secteur touristique repose de plus en plus sur des informations numeriques diffusees sur le web et sur mobile. Toutefois, ces informations sont souvent dispersees, heterogenes et parfois insuffisamment verifiees, ce qui limite leur fiabilite pour les visiteurs. Dans ce contexte, MoroccoCheck a ete concu comme une plateforme touristique communautaire focalisee sur la consultation de lieux, la verification terrain par geolocalisation et la moderation des contenus.

La solution developpee repose sur une architecture fullstack composee de trois sous-systemes : une API REST Node.js / Express connectee a une base MySQL, une application Flutter destinee aux touristes, contributeurs et professionnels, et une interface React dediee a l'administration. Le systeme permet notamment la gestion des comptes, la consultation des sites, la publication d'avis, la realisation de check-ins GPS, l'attribution de badges, la gestion professionnelle des etablissements et la moderation centralisee.

Sur le plan technique, le projet mobilise plusieurs technologies modernes, notamment Express, MySQL, Flutter, Provider, GoRouter, React, Firebase et Sentry. Les tests backend disponibles, l'organisation modulaire du code et les validations effectuees montrent qu'une base fonctionnelle solide a ete mise en place. Le projet repond ainsi a un besoin reel de fiabilisation communautaire de l'information touristique, tout en offrant des perspectives d'evolution vers une plateforme plus large, plus analytique et plus riche en automatisation.

**Mots-cles :** tourisme numerique, geolocalisation, API REST, Flutter, moderation, MySQL, application communautaire

---

## ABSTRACT (Anglais - 180-220 mots)

The tourism sector increasingly depends on digital information distributed through web and mobile platforms. However, such information is often scattered, heterogeneous and not always sufficiently verified, which reduces its reliability for visitors. In this context, MoroccoCheck was designed as a community-driven tourism platform focused on place discovery, on-site verification through geolocation and content moderation.

The implemented solution relies on a fullstack architecture composed of three main subsystems: a Node.js / Express REST API connected to a MySQL database, a Flutter application intended for tourists, contributors and professionals, and a React-based administration interface. The platform supports user account management, site browsing, review publication, GPS-based check-ins, badge attribution, professional venue management and centralized moderation workflows.

From a technical perspective, the project uses several modern technologies including Express, MySQL, Flutter, Provider, GoRouter, React, Firebase and Sentry. The available backend tests, the modular code organization and the validation steps carried out during the analysis indicate that a solid functional foundation has been established. The project therefore addresses a real need for community-based verification of tourism information while opening realistic perspectives for future extensions, richer analytics and more advanced automation capabilities.

**Keywords:** digital tourism, geolocation, REST API, Flutter, moderation, MySQL, community platform

---

## INTRODUCTION GENERALE

### Contexte et motivation

La transformation numerique a modifie les usages lies au tourisme. Les visiteurs s'appuient largement sur les applications mobiles, les cartes interactives, les avis en ligne et les reseaux sociaux pour preparer un deplacement ou choisir un lieu a visiter. Cette dependance aux outils numeriques rend la qualite, l'actualite et la fiabilite de l'information particulierement importantes.

Dans ce contexte, MoroccoCheck se positionne comme une solution orientee verification communautaire. Le projet ne se limite pas a l'affichage de fiches touristiques : il integre des check-ins geolocalises, des avis, un systeme de progression, un espace professionnel et une interface d'administration. Cette orientation repond a un besoin concret : disposer d'une information touristique plus fiable, mieux moderee et plus proche du terrain.

### Problematique

Comment concevoir une plateforme touristique capable de centraliser des informations utiles sur les lieux a visiter tout en garantissant un meilleur niveau de confiance grace a la verification geolocalisee, a la participation communautaire et a la moderation des contenus ?

### Objectifs du projet

- Concevoir et developper une plateforme fullstack dediee a la consultation et a la valorisation de lieux touristiques.
- Mettre en place une API REST securisee pour gerer utilisateurs, sites, avis, check-ins, badges et moderation.
- Implementer une application Flutter ergonomique permettant la consultation mobile, les check-ins GPS et la gestion du profil.
- Fournir un espace professionnel pour la revendication et la gestion d'etablissements.
- Proposer un back-office d'administration permettant la moderation des sites, des avis et des utilisateurs.
- Assurer un niveau satisfaisant de fiabilite via la validation des donnees, les sessions, les roles et les tests disponibles.
- Poser une base evolutive permettant l'ajout de nouvelles villes, d'analyses plus fines et de mecanismes communautaires supplementaires.

### Organisation du rapport

Ce rapport est organise en trois chapitres :

- Le Chapitre 1 presente l'analyse de l'existant et l'etude des besoins du systeme.
- Le Chapitre 2 decrit la conception de la solution : architecture, modelisation UML et base de donnees.
- Le Chapitre 3 detaille la realisation technique, l'environnement de developpement et la presentation de l'application.
- La conclusion generale dresse le bilan du travail accompli et ouvre sur des perspectives d'evolution.

---

## CONCLUSION GENERALE

### Bilan du travail realise

Le projet MoroccoCheck avait pour ambition de proposer une plateforme touristique communautaire alliant consultation de lieux, fiabilisation des informations et verification terrain. L'analyse du depot montre que cet objectif a ete concretise par une architecture coherente, une base de donnees riche, une API REST structuree et deux interfaces distinctes pour les utilisateurs finaux et les administrateurs.

Concretement, le travail realise couvre l'authentification, la navigation par roles, la consultation et la gestion des sites, la publication d'avis, les check-ins geolocalises, la gamification, l'espace professionnel et les fonctions de moderation. Le projet ne se limite donc pas a un prototype visuel ; il s'appuie sur une logique metier reelle, des scripts SQL completes, des tests backend et une integration continue.

Les objectifs principaux peuvent etre consideres comme largement atteints sur le plan fonctionnel et architectural. Quelques elements restent toutefois a stabiliser pour une livraison totalement finalisee, notamment certaines captures du rapport, quelques tests Flutter a re-aligner avec l'interface actuelle et certaines optimisations d'experience utilisateur sur terminaux modestes.

### Difficultes rencontrees

- Multiplicite des clients : la presence de trois sous-systemes (backend, Flutter, admin React) augmente la charge de coherence technique ; ce point a ete surmonte par une API REST centralisee et des roles bien definis.
- Gestion des medias : l'affichage des images sur Flutter web a ete perturbe par des headers de securite et des URLs relatives ; la resolution a passe par la correction du CORS/CORP sur `/uploads` et la normalisation des URLs cote client.
- Verification GPS : la conception d'un check-in fiable est plus complexe qu'une simple geolocalisation ; des regles de distance, de precision et de duree de visite ont ete integrees dans les services backend.
- Cohabitation des roles : l'application gere touristes, contributeurs, professionnels et administrateurs ; cette complexite a ete maitrisee grace aux middlewares d'autorisation et au routage protege.
- Synchronisation entre interface et tests : certaines modifications UI ont rendu quelques assertions Flutter obsoletes ; une revalidation des tests front reste a effectuer pour harmoniser totalement l'ensemble.

### Perspectives

- Etendre le catalogue localise a d'autres villes marocaines avec la meme architecture de medias locaux et de donnees controlees.
- Renforcer la cartographie en migrant, si necessaire, vers une solution plus premium comme Google Maps lorsque le contexte budgetaire et technique le permettra.
- Ajouter des rapports analytiques plus pousses pour les professionnels : frequentation, tendances d'avis, conversion des vues en interactions.
- Ameliorer la couche hors ligne et la synchronisation differee pour les check-ins realises dans des zones a faible couverture reseau.
- Finaliser la couverture de tests Flutter et produire des rapports de couverture automatiques dans la CI.
- Introduire des mecanismes de recommandation personnalisee a partir de l'historique de consultation, des favoris et des interactions geographiques.

---

## LISTE DES ABREVIATIONS

| Sigle | Signification complete |
|-------|------------------------|
| API | Application Programming Interface |
| REST | Representational State Transfer |
| JWT | JSON Web Token |
| GPS | Global Positioning System |
| UI | User Interface |
| UX | User Experience |
| ORM | Object-Relational Mapping |
| SQL | Structured Query Language |
| CRUD | Create, Read, Update, Delete |
| CI | Continuous Integration |
| SPA | Single Page Application |
| KPI | Key Performance Indicator |
| PFE | Projet de Fin d'Etudes |
| ESTA | Ecole Superieure de Technologie d'Agadir |
| MCD | Modele Conceptuel de Donnees |
| MLD | Modele Logique de Donnees |
| DTO | Data Transfer Object |
| HTTP | HyperText Transfer Protocol |
| CORS | Cross-Origin Resource Sharing |
| CORP | Cross-Origin-Resource-Policy |
| SDK | Software Development Kit |

---

## BIBLIOGRAPHIE & WEBOGRAPHIE

[1] "Express - Node.js web application framework," [En ligne]. Disponible : https://expressjs.com/. [Consulte le : 28/03/2026].

[2] "Flutter documentation," [En ligne]. Disponible : https://docs.flutter.dev/. [Consulte le : 28/03/2026].

[3] "Dart documentation," [En ligne]. Disponible : https://dart.dev/guides. [Consulte le : 28/03/2026].

[4] "React documentation," [En ligne]. Disponible : https://react.dev/. [Consulte le : 28/03/2026].

[5] "Vite documentation," [En ligne]. Disponible : https://vite.dev/guide/. [Consulte le : 28/03/2026].

[6] "MySQL 8.0 Reference Manual," [En ligne]. Disponible : https://dev.mysql.com/doc/. [Consulte le : 28/03/2026].

[7] "Firebase documentation," [En ligne]. Disponible : https://firebase.google.com/docs. [Consulte le : 28/03/2026].

[8] "Sentry documentation," [En ligne]. Disponible : https://docs.sentry.io/. [Consulte le : 28/03/2026].

[9] R. Fielding, "Architectural Styles and the Design of Network-based Software Architectures," Doctoral dissertation, University of California, Irvine, 2000.

[10] M. Fowler, *Patterns of Enterprise Application Architecture*, Addison-Wesley, 2002.

[11] I. Sommerville, *Software Engineering*, 10th ed., Pearson, 2015.

[12] P. Pressman and B. Maxim, *Software Engineering: A Practitioner's Approach*, 8th ed., McGraw-Hill, 2014.

[13] "go_router package," [En ligne]. Disponible : https://pub.dev/packages/go_router. [Consulte le : 28/03/2026].

[14] "Provider package," [En ligne]. Disponible : https://pub.dev/packages/provider. [Consulte le : 28/03/2026].

[15] "flutter_map documentation," [En ligne]. Disponible : https://docs.fleaflet.dev/. [Consulte le : 28/03/2026].
