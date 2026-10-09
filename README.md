# Prévision horaire de la consommation électrique française

Ce projet compare cinq méthodes de prévision sur les données RTE : persistance, naïf à 24 heures, naïf à 168 heures, ETS et ARIMA saisonnier. Les données sont ramenées à une grille horaire UTC ; les modèles sont évalués chronologiquement, sans données futures dans l'entraînement.

**Les résultats initiaux (RMSE ETS de 7 231 MW et « 1,15 million d'observations horaires ») ont été invalidés par l'audit du traitement temporel.** Le dataset initial contenait des horodatages répétés et l'échantillonnage perdait la fréquence saisonnière. Les résultats courants sont dans le [rapport recalculé](docs/resultats_corriges/RAPPORT.md), avec les [scores de validation](docs/resultats_corriges/metriques_validation.csv), les [scores de test](docs/resultats_corriges/metriques_test.csv) et le [protocole reproductible](docs/resultats_corriges/protocole.json).

## Exécuter

Depuis un terminal :

```sh
git clone https://github.com/yahya-rl-2002/Projet-energie-france.git
cd Projet-energie-france
Rscript -e 'install.packages(c("data.table", "forecast", "jsonlite"), repos="https://cloud.r-project.org")'
Rscript tests/test_pipeline_horaire.R
Rscript tests/test_exports_horaires.R
Rscript EXECUTER_TOUT.R
```

Dans R/RStudio, depuis la racine :

```r
source("EXECUTER_TOUT.R")
resultats <- executer_pipeline_horaire()
```

Les données brutes volumineuses ne sont pas versionnées. Placer les fichiers `RTE_annuels_combines.csv` et `RTE_en_cours_combines.csv` dans `data/RTE/` (colonnes `Date`, `Heures`, `Consommation`, dates civiles Europe/Paris). Le [téléchargement officiel RTE](https://www.rte-france.com/donnees-publications/eco2mix-donnees-temps-reel/telecharger-indicateurs) et le collecteur historique `01_Donnees/lecture_donnees_RTE.R` restent disponibles pour préparer les sources. Le pipeline ne télécharge rien automatiquement.

Si aucun fichier RTE n'est présent, le pipeline peut récupérer uniquement `Date` et `Consommation` depuis l'ancien `data/dataset_complet.csv`. Les doublons identiques sont retirés et les contradictions provoquent une erreur. Ce mode de repli est signalé dans le manifeste ; il ne peut pas restituer les données perdues par un ancien traitement.

Les anciens fichiers sont conservés. Le nouveau dataset est écrit dans `data/dataset_horaire.csv`, les prévisions détaillées dans `data/resultats_corriges/` et les petits résultats partageables dans `docs/resultats_corriges/`.

## Protocole

- Consommation en MW : moyenne horaire pondérée par la cadence de mesure de 15 ou 30 minutes ; une heure partielle reste manquante.
- Fuseau source explicite : Europe/Paris ; grille et horizons en UTC. Les heures civiles ambiguës d'automne et inexistantes du printemps sont exclues et comptées. Aucune désambiguïsation inventée.
- Fenêtre d'entraînement récente et contiguë de 56 jours. Petits trous remplis uniquement à partir du passé ; aucune interpolation des cibles.
- Validation en 2024, test final en 2025, une origine par mois. Chaque origine prévoit les 168 heures suivantes ; les scores à 1/24/168 h regroupent les pas 1 à H.
- Modèle sélectionné sur la RMSE à 24 h de validation, avant calcul des scores de test. Les cinq modèles restent comparés sur les mêmes dates ; un échec de modèle arrête le calcul.
- MASE calculé avec les différences à 24 h sur l'entraînement. R² indéfini renvoyé `NA`. Couverture et largeur des intervalles ETS/ARIMA publiées ensemble.

La configuration est dans [config_horaire.json](config_horaire.json). Le [rapport](docs/resultats_corriges/RAPPORT.md) précise les limites : échantillon d'origines mensuelles, historique consolidé, heures manquantes, absence de variables exogènes. Un score meilleur que l'ancien ne mesure pas un gain direct, car le protocole a changé.

Les prévisions exportées commencent après la dernière observation des fichiers, actuellement en novembre 2025. **Ce ne sont pas des prévisions à la date d'aujourd'hui.**

## Dashboard et rapport

```r
install.packages(c("shiny", "rmarkdown", "knitr"))
source("06_Dashboard/lancer_dashboard.R")
# Ou produire le rapport depuis les mêmes résultats :
rmarkdown::render("07_Rapport/rapport.Rmd", output_format = "html_document")
```

Le dashboard lit uniquement les résultats corrigés ; il ne recalcule pas d'ancien modèle. Les CSV de synthèse versionnés permettent de l'utiliser sans télécharger tout l'historique.

Les conventions détaillées et la migration sont décrites dans la [méthodologie corrigée](docs/METHODOLOGIE_CORRIGEE.md).

## Structure et archives

- `00_Utilitaires/series_horaires.R` : contrôle des dates, agrégation, imputation causale, métriques, modèles.
- `01_Donnees/preparer_donnees_horaires.R` : lecture des sources et export horaire.
- `04_Validation/validation_horaire.R` : origines temporelles, validation et test.
- `EXECUTER_TOUT.R` : exécution, exports et rapport cohérents.
- `tests/test_pipeline_horaire.R` : régressions sur doublons, cadence, changements d'heure, absence de fuite, métriques et références naïves.
- `archives/pipeline_initial/` : code initial conservé pour traçabilité, non supporté.

Les anciens points d'entrée de modélisation, validation et prévision redirigent vers le pipeline commun. Les anciennes analyses exploratoires, les documents LaTeX et les images historiques ne constituent pas les résultats validés actuels. SARIMAX, tests de robustesse spécifiques et scénarios économiques ne sont pas revendiqués par cette version.

Références : [validation chronologique](https://otexts.com/fpp3/tscv.html), [métriques et MASE](https://otexts.com/fpp3/accuracy.html).

Auteur : Yahya Rahil. Code sous licence MIT ; les données RTE conservent leurs conditions d'utilisation propres.
