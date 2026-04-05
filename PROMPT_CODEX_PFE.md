# PROMPT POUR CODEX — Génération du dossier de documentation PFE

---

## 🎯 Ta mission

Tu es un assistant expert en analyse de code source et en rédaction académique.
Analyse **tout le code source de ce projet** en profondeur, puis génère **4 fichiers Markdown détaillés**
qui serviront à produire un rapport de Projet de Fin d'Études (PFE) professionnel en LaTeX.

Le rapport suit la structure officielle de l'**École Supérieure de Technologie d'Agadir (ESTA)**,
filière **DUT — Conception et Développement de Logiciel**, Université Ibn Zohr — Agadir.

---

## 🔍 Phase 1 — Analyse obligatoire avant toute génération

Avant d'écrire le moindre fichier, **lis et explore** systématiquement :

| Quoi explorer | Pourquoi |
|---------------|----------|
| Tous les fichiers source (`.js` `.ts` `.py` `.java` `.php` `.dart` etc.) | Comprendre la logique métier et les fonctionnalités |
| `package.json` / `requirements.txt` / `pom.xml` / `pubspec.yaml` | Identifier les technologies, frameworks, versions |
| Fichiers de schéma DB (migrations, modèles ORM, `.sql`, Prisma schema) | Construire le MCD/MLD et le diagramme de classes |
| Routes / controllers / endpoints | Identifier les cas d'utilisation et besoins fonctionnels |
| `README.md` existants | Comprendre le contexte général |
| Dossiers `docs/` `screenshots/` `assets/` `public/` | Repérer les ressources disponibles |
| Fichiers `.env.example` / `config/` | Identifier l'environnement technique |
| Commentaires dans le code | Recueillir les intentions du développeur |

**Ne suppose rien. Déduis tout du code réel.**

---

## 📁 Phase 2 — Génère exactement ces 4 fichiers

### ═══════════════════════════════════════════════════════
### FICHIER 1 : `pfe_docs/01_identite_projet.md`
### ═══════════════════════════════════════════════════════

Ce fichier contient toutes les métadonnées du rapport. Remplis chaque champ avec les vraies valeurs détectées.

```markdown
# Identité du Projet PFE

## Établissement
- Université : Université Ibn Zohr — Agadir
- École : École Supérieure de Technologie d'Agadir (ESTA)
- Département : Département Informatique
- Diplôme : DUT — Conception et Développement de Logiciel
- Année universitaire : 2025 / 2026

## Titre du projet
- Titre complet : [déduit du README, du nom du repo, ou des commentaires du code]
- Domaine : [Web / Mobile / IA / IoT / Data / Desktop / autre — déduit des technologies]
- Type : [Application web / API REST / Application mobile / Système embarqué / autre]

## Équipe
- Étudiant 1 : [Prénom NOM — à laisser vide si non trouvé dans le code ou README]
- Étudiant 2 : [Prénom NOM — si binôme]

## Encadrement & Jury
- Encadrante pédagogique : Pr. Aïcha BAKKI
- Encadrant entreprise : [si détecté, sinon "N/A"]
- Jury membre 1 : Pr. Abderrahim SABOUR
- Jury membre 2 : Pr. Aïcha BAKKI

## Soutenance
- Date : 30 / 03 / 2026

## Contexte de réalisation
- Type : [Stage en entreprise / Projet académique interne]
- Entreprise : [si stage : nom, ville, secteur — sinon "N/A"]
- Période : [déduite du git log ou des dates dans les fichiers]
```

---

### ═══════════════════════════════════════════════════════
### FICHIER 2 : `pfe_docs/02_analyse_et_conception.md`
### ═══════════════════════════════════════════════════════

Ce fichier couvre les **Chapitres 1 et 2** du rapport. Rédige en **français académique soigné**.
Utilise "nous" ou la forme impersonnelle. Sois précis, concret, et basé sur le code réel.

```markdown
# Analyse de l'existant, Besoins et Conception

---

## CHAPITRE 1 — Analyse de l'existant et étude des besoins

### 1.1 Contexte du projet
[
  Rédige 2-3 paragraphes qui expliquent :
  - Le domaine métier dans lequel s'inscrit le projet
  - Le problème concret que ce projet résout
  - Qui sont les utilisateurs cibles
  - Pourquoi ce projet est pertinent aujourd'hui
  Base-toi sur le README, les noms des routes, les modèles de données, et la logique métier du code.
]

### 1.2 Étude de l'existant

#### 1.2.1 Solutions existantes
[
  Identifie 3 à 5 outils/applications existants qui résolvent un problème similaire.
  Pour chacun, donne : nom, description, fonctionnalités clés, avantages.
  Présente sous forme de tableau Markdown.
]

| Solution | Description | Fonctionnalités clés | Avantages |
|----------|-------------|---------------------|-----------|
| ... | ... | ... | ... |

#### 1.2.2 Critique de l'existant
[
  Explique en 1-2 paragraphes les limites des solutions ci-dessus et
  pourquoi un nouveau développement est justifié.
  Sois spécifique aux lacunes que CE projet comble.
]

### 1.3 Spécification des besoins

#### 1.3.1 Besoins fonctionnels
[
  Liste TOUS les besoins fonctionnels déduits des routes, controllers,
  composants UI, et modèles de données du projet.
  Format : "BFxx — Le système doit permettre à [acteur] de [action]."
  Minimum 8 besoins fonctionnels.
]

- BF01 — Le système doit permettre à ...
- BF02 — Le système doit permettre à ...
[continuer pour toutes les fonctionnalités détectées]

#### 1.3.2 Besoins non fonctionnels
[
  Déduis les contraintes techniques réelles du projet.
  Exemples : performance (temps de réponse), sécurité (authentification, chiffrement),
  disponibilité, scalabilité, maintenabilité, compatibilité navigateurs/appareils.
]

- BNF01 — Performance : ...
- BNF02 — Sécurité : ...
- BNF03 — Compatibilité : ...
- BNF04 — Maintenabilité : ...

### 1.4 Conclusion
[
  Paragraphe de synthèse du chapitre 1.
  Rappelle les principaux besoins identifiés et annonce le chapitre de conception.
]

---

## CHAPITRE 2 — Conception de la solution

### 2.1 Architecture globale
[
  Décris l'architecture réelle du projet (MVC, client-serveur, REST API, microservices, etc.)
  en te basant sur la structure des dossiers et les fichiers de configuration.
  
  Précise :
  - Le pattern architectural choisi et pourquoi
  - La communication entre les couches (frontend/backend, API, base de données)
  - Les technologies pour chaque couche
  
  Inclus une description textuelle détaillée d'un schéma d'architecture global
  (même si le schéma lui-même sera fait séparément en LaTeX/TikZ).
]

### 2.2 Modélisation UML

#### 2.2.1 Diagramme de cas d'utilisation
[
  Identifie tous les acteurs du système depuis les rôles/permissions dans le code.
  Liste TOUS les cas d'utilisation avec leur description.
  
  Format :
  Acteurs : [liste]
  
  Cas d'utilisation :
  - UC01 — [Acteur] : [Action] → [Description détaillée]
  - UC02 — ...
  
  Décris aussi les relations include/extend si applicables.
]

#### 2.2.2 Diagramme de classes
[
  Liste toutes les entités/classes du projet avec :
  - Leurs attributs (nom : type)
  - Leurs méthodes principales
  - Les relations entre elles (association, héritage, composition, agrégation)
  - Les cardinalités (1..1, 1..*, etc.)
  
  Base-toi sur les modèles ORM, les schémas de base de données, ou les interfaces TypeScript.
  
  Format textuel qui permettra de dessiner le diagramme :
  Classe NomClasse {
    - attribut1 : type
    - attribut2 : type
    + méthode1() : type_retour
  }
  NomClasse1 "1" --> "*" NomClasse2 : relation
]

#### 2.2.3 Diagrammes de séquence
[
  Décris en détail les 3 scénarios les plus importants de l'application.
  Pour chaque scénario, liste la séquence complète d'interactions entre les composants.
  
  Scénario 1 : [ex: Authentification / Connexion]
  Acteur → Frontend → Backend → Base de données → ...
  
  Scénario 2 : [Fonctionnalité principale du projet]
  ...
  
  Scénario 3 : [Autre fonctionnalité critique]
  ...
]

### 2.3 Conception de la base de données

#### 2.3.1 Modèle conceptuel (MCD)
[
  Décris toutes les entités, leurs attributs, et leurs associations.
  Inclus les cardinalités.
  
  Format :
  ENTITE_1 (attribut1 [PK], attribut2, attribut3)
  ENTITE_2 (attribut1 [PK], attribut2, #id_entite1 [FK])
  
  Association :
  ENTITE_1 (1,n) ——[NOM_RELATION]—— (0,1) ENTITE_2
]

#### 2.3.2 Modèle logique (MLD)
[
  Traduis le MCD en schéma relationnel complet.
  
  Format :
  TABLE1(champ1, champ2, champ3)
  TABLE2(champ1, champ2, #champ_fk → TABLE1.champ1)
  
  Indique : clés primaires (souligné / [PK]), clés étrangères (#champ [FK → Table.champ])
]

### 2.4 Conclusion
[
  Synthèse du chapitre 2. Rappelle les choix de conception majeurs.
  Annonce la phase de réalisation.
]
```

---

### ═══════════════════════════════════════════════════════
### FICHIER 3 : `pfe_docs/03_realisation.md`
### ═══════════════════════════════════════════════════════

Ce fichier couvre le **Chapitre 3** du rapport. Sois le plus précis et technique possible.

```markdown
# Réalisation et Implémentation

---

## CHAPITRE 3 — Réalisation et implémentation

### 3.1 Environnement de développement

#### Langages et frameworks
[
  Liste TOUS les langages, frameworks et bibliothèques utilisés avec leurs versions exactes
  (depuis package.json, requirements.txt, etc.)
  
  Format tableau :
]

| Technologie | Version | Rôle dans le projet |
|-------------|---------|---------------------|
| ... | ... | ... |

#### Outils de développement
[
  IDE, gestionnaire de versions, outils de test, déploiement, etc.
]

| Outil | Version | Usage |
|-------|---------|-------|
| VS Code / autre | ... | Éditeur de code |
| Git | ... | Contrôle de version |
| ... | ... | ... |

#### Environnement d'exécution
[
  Serveur, base de données, environnement cloud ou local, OS cible.
]

### 3.2 Développement

#### 3.2.1 Structure du projet
[
  Génère l'arborescence COMPLÈTE et RÉELLE du projet (tous les dossiers et fichiers importants).
  Pour chaque dossier principal, explique son rôle en une phrase.
  
  Format :
  projet/
  ├── dossier1/          ← [rôle : ...]
  │   ├── fichier1.ext   ← [rôle : ...]
  │   └── fichier2.ext   ← [rôle : ...]
  ├── dossier2/          ← [rôle : ...]
  └── fichier_racine     ← [rôle : ...]
]

#### 3.2.2 Implémentation des fonctionnalités principales
[
  Présente les 5 fonctionnalités les plus importantes du projet.
  Pour chacune :
  - Titre de la fonctionnalité
  - Description technique de comment elle est implémentée
  - Extrait du code source réel le plus représentatif (10-25 lignes max)
  - Explication ligne par ligne des choix techniques
  
  Format :
  
  **Fonctionnalité 1 : [Titre]**
  Description : ...
  Fichier : `chemin/vers/fichier.ext`
  
  ```[langage]
  [extrait de code réel]
  ```
  
  Explication : ...
  
  [Répéter pour chaque fonctionnalité]
]

### 3.3 Présentation de l'application
[
  Décris chaque interface/écran principal de l'application dans l'ordre du flux utilisateur.
  Pour chaque interface :
  - Nom de l'interface
  - Chemin/route correspondante
  - Description de ce qu'elle affiche et permet de faire
  - Capture d'écran disponible ? (chemin dans le projet : `screenshots/...` ou `docs/...`)
  
  Si des captures existent dans le projet, liste leurs chemins exacts.
  Si non, décris précisément ce que chaque écran devrait montrer pour que des captures soient prises.
]

| Interface | Route | Description | Capture disponible |
|-----------|-------|-------------|-------------------|
| Page d'accueil | `/` | ... | `screenshots/home.png` ou NON |
| ... | ... | ... | ... |

### 3.4 Tests et validation
[
  Si des fichiers de tests existent dans le projet (jest, pytest, JUnit, etc.) :
  - Liste les types de tests implémentés
  - Donne le taux de couverture si disponible
  - Décris les scénarios de tests principaux
  
  Si aucun test formel : décris comment la validation fonctionnelle a été effectuée.
]

### 3.5 Conclusion
[
  Bilan de la réalisation. Ce qui a été accompli, les choix techniques faits.
  Transition vers la conclusion générale.
]
```

---

### ═══════════════════════════════════════════════════════
### FICHIER 4 : `pfe_docs/04_editorial_et_annexes.md`
### ═══════════════════════════════════════════════════════

Ce fichier couvre tout le contenu éditorial du rapport.

```markdown
# Contenu Éditorial — Pages Préliminaires, Intro, Conclusion, Annexes

---

## PAGE DE GARDE
[
  Reprend les infos de 01_identite_projet.md.
  Rappel de la structure :
  - Logo université (gauche) + Logo ESTA (droite)
  - Université Ibn Zohr — Agadir / ESTA / Département Informatique
  - "PROJET DE FIN D'ÉTUDES"
  - "Pour l'obtention du diplôme DUT — Conception et Développement de Logiciel"
  - Thème : [TITRE DU PROJET]
  - Tableau : Réalisé par [noms] | Encadré par Pr. Aïcha BAKKI
  - Présenté devant le Jury : Pr. Abderrahim SABOUR / Pr. Aïcha BAKKI
  - Soutenu le : 30 / 03 / 2026
]

---

## DÉDICACE
[
  Génère une dédicace sobre et académique (6-10 lignes).
  Style traditionnel de rapport PFE marocain, en français.
  Adapter si 1 ou 2 étudiants selon ce détecté dans le fichier 01.
]

---

## REMERCIEMENTS
[
  Rédige une page de remerciements sincère et professionnelle (20-30 lignes).
  Mentionner obligatoirement dans cet ordre :
  1. Allah (tradition marocaine)
  2. Les parents et la famille
  3. Pr. Aïcha BAKKI (encadrante pédagogique)
  4. Les membres du jury : Pr. Abderrahim SABOUR et Pr. Aïcha BAKKI
  5. L'institution ESTA et ses enseignants
  6. L'encadrant entreprise (si stage détecté)
  7. Les amis et collègues
]

---

## RÉSUMÉ (Français — 180-220 mots)
[
  Rédige le résumé complet en français académique.
  Structure obligatoire :
  Paragraphe 1 : contexte et problématique
  Paragraphe 2 : approche et solution développée
  Paragraphe 3 : technologies utilisées et résultats obtenus
  
  Mots-clés (5-7) : déduits des technologies et du domaine du projet
]

**Mots-clés :** [mot1, mot2, mot3, mot4, mot5]

---

## ABSTRACT (Anglais — 180-220 mots)
[
  Traduis et adapte le résumé en anglais académique soigné.
  Même structure que le résumé français.
]

**Keywords:** [keyword1, keyword2, keyword3, keyword4, keyword5]

---

## INTRODUCTION GÉNÉRALE

### Contexte et motivation
[2 paragraphes : domaine du projet + pourquoi c'est pertinent maintenant]

### Problématique
[2-3 phrases formulant clairement LE problème central que ce projet résout]

### Objectifs du projet
[
  Liste de 5-7 objectifs concrets et mesurables.
  Format : verbe d'action + résultat attendu + critère de succès si possible.
]
- Concevoir et développer ...
- Implémenter ...
- Assurer ...
- Valider ...

### Organisation du rapport
Ce rapport est organisé en trois chapitres :
- Le Chapitre 1 présente l'analyse de l'existant et l'étude des besoins du système.
- Le Chapitre 2 décrit la conception de la solution : architecture, modélisation UML et base de données.
- Le Chapitre 3 détaille la réalisation technique, l'environnement de développement et la présentation de l'application.
- La conclusion générale dresse le bilan du travail accompli et ouvre sur des perspectives d'évolution.

---

## CONCLUSION GÉNÉRALE

### Bilan du travail réalisé
[
  2-3 paragraphes résumant :
  - Les objectifs initiaux fixés
  - Ce qui a été réalisé concrètement
  - Dans quelle mesure les objectifs ont été atteints
]

### Difficultés rencontrées
[
  3-5 difficultés réelles probables liées aux technologies utilisées.
  Pour chacune : la difficulté + comment elle a été surmontée.
]

### Perspectives
[
  4-6 axes d'amélioration réalistes basés sur les limites actuelles du projet.
  Doivent être spécifiques au projet, pas génériques.
]

---

## LISTE DES ABRÉVIATIONS
[
  Identifie TOUTES les abréviations techniques réellement utilisées dans le projet
  (depuis le code source, les README, les commentaires, les noms de variables/routes).
  Donne la signification complète en français quand possible.
]

| Sigle | Signification complète |
|-------|----------------------|
| API | Application Programming Interface |
| ... | ... |
[ajouter toutes les abréviations spécifiques au projet]

---

## BIBLIOGRAPHIE & WEBOGRAPHIE
[
  Génère minimum 10 références au format IEEE numéroté.
  Inclure obligatoirement :
  - Documentation officielle de CHAQUE framework/bibliothèque utilisé(e) dans le projet
  - 2-3 ouvrages académiques sur le domaine métier du projet
  - Articles ou ressources liés aux concepts architecturaux utilisés (REST, MVC, etc.)
  
  Format IEEE :
  [N] Prénom NOM, "Titre de l'ouvrage/article", Éditeur, Année.
  [N] "Titre de la documentation", [En ligne]. Disponible : URL. [Consulté le : date].
]

[1] ...
[2] ...
...
```

---

## ✅ Règles de qualité pour les 4 fichiers

1. **Langue** : Français académique soigné partout. Jamais de "je". Utiliser "nous" ou forme impersonnelle.
2. **Précision** : Tout ce que tu écris doit être basé sur le code réel. Aucune invention.
3. **Complétude** : Ne laisse aucune section vide. Si une info est vraiment introuvable dans le code, écris `[Information non disponible dans le code source — à compléter manuellement]`.
4. **Niveau de détail** : Chaque section doit être assez détaillée pour être copiée directement dans le rapport LaTeX final sans réécriture majeure.
5. **Cohérence** : Les informations doivent être cohérentes entre les 4 fichiers (même titre de projet, mêmes noms, mêmes technologies).

---

## 🚀 Ordre d'exécution

1. Explore le projet (Phase 1)
2. Génère `01_identite_projet.md`
3. Génère `02_analyse_et_conception.md`
4. Génère `03_realisation.md`
5. Génère `04_editorial_et_annexes.md`
6. Affiche un **résumé final** listant :
   - Les sections complétées automatiquement ✅
   - Les sections à compléter manuellement ⚠️ (avec indication de ce qui manque)
   - Les captures d'écran à prendre 📸
   - Les diagrammes à créer ou exporter 📊
