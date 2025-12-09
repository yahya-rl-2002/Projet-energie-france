# 🚀 Guide de Configuration Git

Ce guide vous explique comment initialiser Git et publier ce projet sur GitHub.

## 📋 Prérequis

- Git installé sur votre machine
- Compte GitHub créé
- Accès au repository (créé sur GitHub)

## 🔧 Étapes d'installation

### 1. Initialiser Git (si pas déjà fait)

```bash
cd "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION"

# Initialiser Git
git init

# Vérifier le statut
git status
```

### 2. Configurer Git (si pas déjà fait)

```bash
# Configurer votre nom et email
git config user.name "Yahya Rahil"
git config user.email "yahya.rahil@etu.u-bordeaux.fr"

# Vérifier la configuration
git config --list
```

### 3. Ajouter les fichiers

```bash
# Ajouter tous les fichiers (respecte .gitignore)
git add .

# Vérifier ce qui sera commité
git status
```

### 4. Premier commit

```bash
# Créer le premier commit
git commit -m "Initial commit: Système de prévision énergétique française

- Collecte et intégration de données (RTE, Météo France, INSEE, Eurostat)
- Implémentation de 4 modèles de séries temporelles (ETS, ARIMA, TBATS, SARIMAX)
- Analyses exploratoires avancées
- Validation croisée et tests de robustesse
- Prévisions multi-horizons
- Dashboard Shiny interactif
- Rapports LaTeX professionnels"
```

### 5. Créer le repository sur GitHub

1. Aller sur [GitHub](https://github.com)
2. Cliquer sur "New repository"
3. Nommer le repository : `projet-energie-france`
4. Description : "Système intelligent de prévision de la consommation électrique française"
5. Choisir Public ou Private
6. **NE PAS** initialiser avec README, .gitignore ou LICENSE (déjà créés)
7. Cliquer sur "Create repository"

### 6. Connecter le repository local à GitHub

```bash
# Ajouter le remote (remplacer YOUR_USERNAME par votre username GitHub)
git remote add origin https://github.com/YOUR_USERNAME/projet-energie-france.git

# Vérifier le remote
git remote -v
```

### 7. Pousser le code sur GitHub

```bash
# Renommer la branche principale en 'main' (si nécessaire)
git branch -M main

# Pousser le code
git push -u origin main
```

## 📝 Commandes Git utiles

### Voir l'historique

```bash
git log --oneline
git log --graph --oneline --all
```

### Ajouter des modifications

```bash
# Voir les modifications
git status

# Ajouter un fichier spécifique
git add nom_du_fichier.R

# Ajouter tous les fichiers modifiés
git add .

# Commit
git commit -m "Description des modifications"

# Pousser
git push
```

### Créer une branche pour une nouvelle fonctionnalité

```bash
# Créer et changer de branche
git checkout -b nouvelle-fonctionnalite

# Faire des modifications, puis commit
git add .
git commit -m "Ajouter nouvelle fonctionnalité"

# Pousser la branche
git push -u origin nouvelle-fonctionnalite
```

### Mettre à jour depuis GitHub

```bash
# Récupérer les dernières modifications
git pull origin main
```

## ⚠️ Fichiers non versionnés

Les fichiers suivants sont **intentionnellement** exclus du versioning (voir `.gitignore`) :

- `data/dataset_complet.csv` (trop volumineux)
- `data/RTE/*.xls` (fichiers Excel volumineux)
- `data/resultats_nouveaux/**/*.csv` (résultats générés)
- `figures/**/*.png` (graphiques générés)
- `logs/*.log` (logs d'exécution)
- `*.pdf` (rapports générés)

Ces fichiers peuvent être régénérés en exécutant les scripts appropriés.

## 🔐 Sécurité

**IMPORTANT** : Ne jamais commiter :
- Clés API
- Mots de passe
- Fichiers `.env`
- Données sensibles

Ces fichiers sont déjà dans `.gitignore`, mais vérifiez avant chaque commit.

## 📚 Ressources

- [Documentation Git](https://git-scm.com/doc)
- [GitHub Guides](https://guides.github.com/)
- [Git Cheat Sheet](https://education.github.com/git-cheat-sheet-education.pdf)

## ✅ Vérification finale

Après avoir poussé le code, vérifiez sur GitHub que :
- ✅ Le README.md s'affiche correctement
- ✅ Tous les fichiers R sont présents
- ✅ La structure des dossiers est correcte
- ✅ Les fichiers volumineux ne sont pas présents (comme prévu)

---

**Problème ?** Ouvrez une issue sur GitHub ou contactez le mainteneur.

