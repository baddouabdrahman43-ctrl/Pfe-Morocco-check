# 01 - Presentation Generale

## 1. Idee generale du projet

`MoroccoCheck` est une plateforme numerique orientee tourisme. Elle permet a des utilisateurs de decouvrir des sites touristiques, de consulter des informations, de publier des avis et d'effectuer des check-ins geolocalises. Le projet ajoute aussi une dimension de progression utilisateur avec badges, points, historique et leaderboard.

Le projet n'est pas une simple application vitrine. Il s'agit d'un ecosysteme complet compose de trois applications qui cooperent :

- une API backend centralisee
- une application mobile Flutter pour les utilisateurs finaux
- une interface web d'administration pour les moderateurs et administrateurs

## 2. Problematique a laquelle le projet repond

Dans un contexte touristique, il est souvent difficile de centraliser :

- des fiches de lieux fiables
- des retours utilisateurs moderes
- une verification partielle de la presence reelle sur place
- des outils de gestion pour les professionnels et les administrateurs

`MoroccoCheck` tente de repondre a cette problematique avec une approche communautaire et controlee :

- la communaute peut consulter, noter et enrichir l'information
- les check-ins GPS servent a renforcer la dimension terrain
- les professionnels peuvent demander une relation avec des fiches de sites
- les administrateurs disposent d'un espace de moderation dedie

## 3. Objectifs du projet

Les objectifs principaux peuvent etre presentes ainsi :

- proposer une application touristique moderne
- structurer un catalogue de sites touristiques
- offrir une experience mobile centree sur l'utilisateur
- creer une logique d'engagement via gamification
- prevoir un circuit de moderation pour garder la qualite du contenu
- separer clairement les usages utilisateur, professionnel et administrateur

## 4. Public cible

Le systeme distingue plusieurs profils.

### Touriste

Le touriste peut :

- creer un compte
- consulter les sites
- voir les details
- publier des avis
- consulter son profil et sa progression

### Contributor

Le contributor represente un utilisateur plus engage. Le projet prevoit un passage de `TOURIST` vers `CONTRIBUTOR` via une demande. Ce role est lie notamment aux check-ins terrain et a une participation plus active.

### Professional

Le professionnel peut :

- revendiquer un site
- consulter ses sites
- voir certaines statistiques
- gerer ou proposer des informations liees a ses etablissements

### Admin

L'administrateur a acces a l'interface `admin-web` et peut :

- consulter les statistiques globales
- moderer les sites
- moderer les avis
- traiter les demandes contributor
- gerer les utilisateurs

## 5. Valeur ajoutee du projet

La valeur du projet repose sur la combinaison de plusieurs idees :

- consultation touristique
- verification de presence terrain
- participation communautaire
- moderation des contenus
- espace professionnel
- back-office d'administration

Cette combinaison rend le sujet interessant pour un PFE, car il couvre a la fois :

- le developpement mobile
- le developpement web
- les API REST
- la base de donnees
- la securite
- l'architecture logicielle

## 6. Vision fonctionnelle du produit

On peut resumer le cycle de vie principal du produit comme suit :

```text
1. Un utilisateur cree un compte ou se connecte
2. Il explore les sites touristiques
3. Il consulte les details d'un site
4. Il effectue un check-in ou laisse un avis
5. Son profil evolue avec points, badges et classement
6. Les administrateurs surveillent et moderent les contenus
```

## 7. Pourquoi ce projet est pertinent en PFE

Ce projet est pertinent pour un PFE car il montre :

- une architecture multi-applications
- une gestion de roles et permissions
- une integration mobile + backend + web admin
- des flux metier realistes
- une persistance de donnees relationnelles
- des contraintes reelles de securite et de deploiement

En soutenance, il peut etre presente comme un projet de plateforme complete plutot que comme une simple application mobile isolee.
