#!/bin/bash
# Script pour compiler le document LaTeX d'interprétation des résultats

echo "🔨 Compilation du document LaTeX d'interprétation..."

# Vérifier que pdflatex est installé
if ! command -v pdflatex &> /dev/null; then
    echo "❌ Erreur: pdflatex n'est pas installé"
    echo "   Installez LaTeX avec: brew install --cask mactex"
    echo "   Ou utilisez TinyTeX: Rscript -e \"tinytex::install_tinytex()\""
    exit 1
fi

# Compiler le document
pdflatex -interaction=nonstopmode INTERPRETATION_RESULTATS.tex

# Compiler une deuxième fois pour les références croisées
pdflatex -interaction=nonstopmode INTERPRETATION_RESULTATS.tex

# Nettoyer les fichiers auxiliaires
rm -f *.aux *.log *.out *.toc

echo "✅ Compilation terminée!"
echo "📄 Fichier PDF créé: INTERPRETATION_RESULTATS.pdf"


