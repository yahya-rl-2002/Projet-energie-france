#!/bin/bash
# Script pour compiler le document LaTeX de comparaison

echo "🔨 Compilation du document LaTeX de comparaison..."

# Vérifier que pdflatex est installé
if ! command -v pdflatex &> /dev/null; then
    echo "❌ Erreur: pdflatex n'est pas installé"
    echo "   Installez LaTeX avec: brew install --cask mactex"
    echo "   Ou utilisez TinyTeX: Rscript -e \"tinytex::install_tinytex()\""
    exit 1
fi

# Compiler le document
pdflatex -interaction=nonstopmode COMPARAISON_ANCIENS_NOUVEAUX.tex

# Compiler une deuxième fois pour les références croisées
pdflatex -interaction=nonstopmode COMPARAISON_ANCIENS_NOUVEAUX.tex

# Nettoyer les fichiers auxiliaires
rm -f *.aux *.log *.out *.toc

echo "✅ Compilation terminée!"
echo "📄 Fichier PDF créé: COMPARAISON_ANCIENS_NOUVEAUX.pdf"


