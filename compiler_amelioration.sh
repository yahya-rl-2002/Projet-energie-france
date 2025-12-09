#!/bin/bash
# Script pour compiler le guide d'amélioration

echo "🔨 Compilation du guide d'amélioration..."

if ! command -v pdflatex &> /dev/null; then
    echo "❌ Erreur: pdflatex n'est pas installé"
    exit 1
fi

pdflatex -interaction=nonstopmode GUIDE_AMELIORATION_RESULTATS.tex
pdflatex -interaction=nonstopmode GUIDE_AMELIORATION_RESULTATS.tex

rm -f *.aux *.log *.out *.toc

echo "✅ Compilation terminée!"
echo "📄 Fichier PDF créé: GUIDE_AMELIORATION_RESULTATS.pdf"


