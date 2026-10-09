# Méthodologie corrigée et migration

Le problème principal de la première version était la définition du temps : des jointures multipliaient les lignes, puis l'échantillonnage par indices supprimait la fréquence R. Les corrections repartent des seules mesures de consommation RTE et centralisent le calcul dans un pipeline commun.

## Données et conventions

Les fichiers locaux fournissent des dates/heures civiles sans décalage UTC. Le pipeline les interprète en Europe/Paris puis construit une grille UTC. L'heure répétée d'automne ne peut pas être reconstruite de façon certaine à partir de ces libellés : les valeurs ambiguës sont exclues et les deux heures UTC restent manquantes. Les valeurs portant l'heure inexistante du printemps sont également exclues. Les exports locaux comportent effectivement de tels libellés ; le pipeline ne les décale pas arbitrairement.

Une mesure de 30 minutes reçoit un poids de 1 800 secondes ; une mesure de 15 minutes, de 900 secondes. La cadence est identifiée par journée. La moyenne horaire n'est conservée que si les mesures couvrent exactement 3 600 secondes. Les heures incomplètes restent NA, y compris la dernière heure du fichier.

Cette agrégation suppose que la mesure représente l'intervalle commençant à son horodatage. Les [spécifications RTE](https://assets.rte-france.com/prod/public/2025-06/Eco2mix%20-%20Sp%C3%A9cifications%20des%20fichiers%20en%20puissance.pdf) distinguent les puissances moyennes consolidées/définitives des puissances instantanées temps réel. Dans les fichiers utilisés, 2012–2023 sont définitifs, 2024 est consolidé et 2025 est en temps réel. La moyenne horaire 2025 est donc une approximation à partir des points instantanés ; elle n'est pas présentée comme une mesure de comptage définitive.

Les sources volumineuses restent locales ; le manifeste contient leurs noms et empreintes MD5 pour identifier exactement l'instantané utilisé. Ces empreintes servent à la reproduction, pas à la sécurité cryptographique.

## Évaluation

Les paramètres sont définis dans `config_horaire.json` avant le test : cinq méthodes, 56 jours d'historique, origines mensuelles, horizons 1/24/168 h. ARIMA utilise une recherche pas à pas approximative bornée (p/q ≤ 2, P/Q ≤ 1) et une fréquence journalière de 24. ETS conserve également cette fréquence.

Le champ `Origine` désigne le début de la dernière heure entièrement observée de l'entraînement. La première heure prévue est `Origine + 1 heure`. La décision peut être prise après réception de cette dernière mesure. Les délais réels de publication des données ne sont pas simulés : il s'agit d'un backtest sur un instantané historique.

L'entraînement de chaque origine ne contient que les heures précédant ses cibles. Les manques courts de l'entraînement sont remplacés par une valeur passée (retard 168 h si disponible, sinon 24 h, sinon dernière valeur). Aucune cible n'est reconstruite. Une origine inadmissible est exclue pour tous les modèles et inscrite au journal ; un échec de modèle interrompt le calcul, au lieu de modifier silencieusement le périmètre de comparaison.

Le modèle choisi sur la RMSE cumulée à 24 h de validation 2024 est figé avant l'évaluation 2025. Les modèles peuvent être réentraînés avec les observations de test devenues passées aux origines suivantes : c'est le fonctionnement d'une fenêtre glissante, sans accès à ses propres cibles futures.

Le R² agrégé compare les erreurs à la variance de toutes les cibles évaluées. Il peut être positif alors que certaines origines sont difficiles ; les métriques par origine sont donc publiées aussi. Le MASE utilise une échelle saisonnière à 24 h calculée séparément sur chaque entraînement. Les intervalles ETS/ARIMA sont des intervalles nominaux, sans recalibration. Aucune probabilité n'est affectée à un scénario économique arbitraire.

## Migration

- `EXECUTER_TOUT.R` est le point d'entrée de référence. En console R, appeler explicitement `executer_pipeline_horaire()` après `source()`.
- `combinaison_donnees.R` prépare désormais le dataset horaire, sans jointures de métadonnées. Il ne remplace pas le dataset original.
- Les anciens lanceurs de modélisation, validation et prévision redirigent vers le calcul commun. Cela remplace les versions divergentes des métriques et évite de relancer une validation par blocs incorrecte.
- Le dashboard et le rapport R Markdown lisent les résultats corrigés. Ils ne s'appuient plus sur les anciens CSV.
- Les implémentations initiales sont conservées dans `archives/pipeline_initial/`. Les anciennes analyses exploratoires, figures, guides et documents LaTeX sont historiques ; ils ne démontrent pas les performances courantes.
- SARIMAX, analyses de robustesse dédiées et scénarios ne font pas partie des résultats corrigés validés. Leur intégration future doit respecter le même protocole et la disponibilité réelle des variables à chaque origine.

## Vérifier

```sh
Rscript tests/test_pipeline_horaire.R
Rscript tests/test_exports_horaires.R
Rscript EXECUTER_TOUT.R
```

Les deux suites de tests utilisent des données synthétiques : elles vérifient notamment la non-contamination par des observations futures et la préservation du fichier d'entrée. L'exécution complète sur les sources locales vérifie en plus les scores réels exportés.
