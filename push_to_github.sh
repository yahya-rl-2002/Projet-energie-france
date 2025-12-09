#!/bin/bash
# Script pour pousser le projet sur GitHub

echo "🚀 Configuration et push vers GitHub"
echo "======================================"
echo ""

# Aller dans le dossier du projet
cd "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION"

# Vérifier si Git est initialisé
if [ ! -d ".git" ]; then
    echo "📦 Initialisation de Git..."
    git init
    echo "✅ Git initialisé"
    echo ""
fi

# Configurer Git (si nécessaire)
echo "⚙️  Configuration Git..."
git config user.name "Yahya Rahil" 2>/dev/null || echo "   (déjà configuré)"
git config user.email "yahya.rahil@etu.u-bordeaux.fr" 2>/dev/null || echo "   (déjà configuré)"
echo "✅ Configuration terminée"
echo ""

# Ajouter le remote (mise à jour si existe déjà)
echo "🔗 Configuration du remote GitHub..."
git remote remove origin 2>/dev/null
git remote add origin https://github.com/yahya-rl-2002/Projet-energie-france.git
echo "✅ Remote configuré: https://github.com/yahya-rl-2002/Projet-energie-france.git"
echo ""

# Ajouter tous les fichiers
echo "📝 Ajout des fichiers..."
git add .
echo "✅ Fichiers ajoutés"
echo ""

# Afficher le statut
echo "📊 Statut Git:"
git status --short | head -20
echo ""

# Demander confirmation
read -p "🤔 Voulez-vous créer le commit et pousser sur GitHub? (o/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
    echo "❌ Opération annulée"
    exit 1
fi

# Créer le commit
echo "💾 Création du commit..."
git commit -m "Initial commit: Système de prévision énergétique française

- Collecte et intégration de données (RTE, Météo France, INSEE, Eurostat)
- Implémentation de 4 modèles de séries temporelles (ETS, ARIMA, TBATS, SARIMAX)
- Analyses exploratoires avancées
- Validation croisée et tests de robustesse
- Prévisions multi-horizons (1h à 1 mois)
- Dashboard Shiny interactif
- Rapports LaTeX professionnels
- Documentation complète"

if [ $? -eq 0 ]; then
    echo "✅ Commit créé avec succès"
    echo ""
    
    # Renommer la branche en main
    echo "🌿 Configuration de la branche main..."
    git branch -M main 2>/dev/null || echo "   (déjà sur main)"
    echo ""
    
    # Pousser sur GitHub
    echo "⬆️  Push vers GitHub..."
    git push -u origin main
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "🎉 SUCCÈS ! Le projet a été poussé sur GitHub"
        echo "🔗 Repository: https://github.com/yahya-rl-2002/Projet-energie-france"
        echo ""
        echo "✅ Prochaines étapes:"
        echo "   1. Vérifier le repository sur GitHub"
        echo "   2. Le README.md devrait s'afficher automatiquement"
        echo "   3. Vérifier que tous les fichiers sont présents"
    else
        echo ""
        echo "❌ Erreur lors du push"
        echo "💡 Vérifiez:"
        echo "   - Votre connexion Internet"
        echo "   - Vos identifiants GitHub"
        echo "   - Les permissions du repository"
    fi
else
    echo "❌ Erreur lors de la création du commit"
    echo "💡 Vérifiez s'il y a des changements à commiter"
fi

