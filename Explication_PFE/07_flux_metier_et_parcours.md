# 07 - Flux Metier Et Parcours

## 1. Pourquoi parler des flux metier

Un bon projet PFE ne se resume pas a des ecrans ou a des tables SQL. Il faut aussi expliquer les parcours utilisateur de bout en bout.

Dans `MoroccoCheck`, plusieurs flux sont importants.

## 2. Flux d'inscription et de connexion

### Etapes

1. L'utilisateur ouvre l'application mobile
2. Il choisit inscription ou connexion
3. Il saisit ses informations ou utilise Google
4. Le front appelle `/api/auth/register`, `/api/auth/login` ou `/api/auth/google`
5. Le backend verifie les donnees
6. Le backend renvoie le profil et le token
7. Le front enregistre la session localement

### Interet metier

Ce flux est la porte d'entree vers toutes les fonctionnalites protegee du systeme.

## 3. Flux de consultation des sites

### Etapes

1. L'utilisateur arrive sur la liste des sites
2. Le front appelle l'API des sites
3. Les sites sont affiches avec des informations essentielles
4. L'utilisateur ouvre le detail d'un site
5. Le front charge les informations, avis et photos lies a ce site

### Interet metier

Ce flux constitue le coeur de la consultation touristique.

## 4. Flux de check-in geolocalise

C'est l'un des flux les plus originaux du projet.

### Etapes

1. L'utilisateur ouvre la fiche d'un site
2. Il choisit l'action de check-in
3. L'application recupere la localisation GPS
4. Le front envoie les coordonnees au backend
5. Le backend verifie les regles de validation
6. Le check-in est enregistre
7. Des points ou elements de progression peuvent etre mis a jour

### Interet metier

Ce flux donne une dimension "presence reelle sur place" au projet, ce qui le differencie d'une simple application d'avis.

## 5. Flux de publication d'avis

### Etapes

1. L'utilisateur consulte un site
2. Il ouvre le formulaire d'avis
3. Il entre note, titre, commentaire et eventuellement photos
4. Le front appelle le backend
5. L'avis est enregistre
6. Selon la logique metier, il peut etre publie ou passer par une moderation

### Extensions visibles dans le projet

- edition de l'avis
- suppression
- affichage de l'historique personnel
- reponse du proprietaire

## 6. Flux de progression utilisateur

Le profil utilisateur ne sert pas seulement a afficher un nom. Il devient un espace de progression.

### Donnees mises en avant

- nombre de check-ins
- nombre d'avis
- badges
- historique
- leaderboard

### Interet

Ce flux augmente l'engagement et donne une logique de gamification.

## 7. Flux de demande contributor

Le projet prevoit un passage du simple utilisateur vers un niveau de participation plus eleve.

### Etapes

1. L'utilisateur ouvre son profil
2. Il consulte son statut contributor
3. S'il est eligible, il envoie une demande
4. Le backend enregistre cette demande
5. L'admin la voit dans le dashboard
6. L'admin l'approuve ou la rejette

### Interet

Ce flux relie le mobile au back-office admin et montre une vraie gouvernance metier.

## 8. Flux professionnel

Le projet prevoit un espace dedie aux professionnels.

### Parcours possibles

- consulter le hub professionnel
- revendiquer un site
- consulter la liste de ses sites
- creer une fiche de site
- modifier un site
- consulter des indicateurs lies a un site
- repondre a des avis

### Interet

Ce flux montre que le projet ne vise pas seulement les touristes, mais aussi les acteurs economiques du secteur.

## 9. Flux de moderation admin

Le dashboard admin centralise plusieurs files d'attente.

### Moderation des sites

1. L'admin ouvre la file des sites en attente
2. Il consulte un site
3. Il choisit une decision
4. Le backend met a jour le statut

### Moderation des avis

1. L'admin ouvre la file des avis
2. Il examine le contenu
3. Il valide, rejette ou signale

### Traitement des demandes contributor

1. L'admin consulte les demandes
2. Il lit les informations du demandeur
3. Il accepte ou refuse

### Gestion des utilisateurs

1. L'admin filtre les comptes
2. Il ouvre une fiche utilisateur
3. Il modifie role ou statut si necessaire

## 10. Flux transversal mobile -> backend -> admin

Un exemple tres parlant :

```text
Utilisateur mobile publie un avis
-> backend enregistre l'avis
-> admin web le recupere dans une file d'attente
-> admin modere
-> l'etat final influence ce qui est visible dans le produit
```

Ce type de flux montre la coherence globale du systeme.

## 11. Comment utiliser ces flux en soutenance

Pour une demo claire, on peut presenter 4 parcours :

1. Connexion mobile puis consultation des sites
2. Check-in ou publication d'avis
3. Passage dans le profil avec statistiques et badges
4. Connexion admin puis moderation du contenu genere

Avec seulement ces quatre parcours, on montre deja toute la richesse de l'architecture.
