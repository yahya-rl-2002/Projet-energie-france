# Résultats du pipeline horaire corrigé

Ces scores remplacent le classement initial. Ils ne sont pas directement comparables aux anciennes métriques : données, dates et horizons ont été corrigés.

Données : 121576 heures UTC, dont 121547 complètes. Les heures absentes restent NA dans le dataset.

## Protocole

Validation : 2024 ; test final : 2025. Fenêtre d'entraînement glissante : 1344 heures (56 jours).
Une origine par mois, avant le 1er à 00 h UTC ; prévision des 168 heures suivantes. Les scores à H portent sur les pas 1 à H, pas uniquement le pas H. Les références de 24/168 h utilisent des heures écoulées UTC, pas toujours la même heure civile autour des changements d'heure.

Les cibles ne sont jamais imputées. Une origine avec une cible manquante est exclue pour tous les modèles et consignée. Les petits trous d'entraînement (maximum 6 heures consécutives) sont remplis uniquement à partir du passé. Les modèles sont réentraînés à chaque origine ; leurs réglages et la sélection ne dépendent pas des scores de test.

Modèle retenu exclusivement sur la RMSE à 24 h de validation : **ARIMA**.

## Validation

| Modele | Horizon | N_origines | RMSE | MAE | MAPE | R_squared | MASE |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Persistance | 1 | 12 | 2126.310 | 1951.542 | 4.283 | 0.917 | 0.794 |
| Naif_24h | 1 | 12 | 1624.249 | 1303.000 | 2.921 | 0.951 | 0.515 |
| Naif_168h | 1 | 12 | 3361.099 | 2096.125 | 4.831 | 0.792 | 0.824 |
| ETS | 1 | 12 | 977.271 | 669.143 | 1.493 | 0.982 | 0.278 |
| ARIMA | 1 | 12 | 692.663 | 359.087 | 0.820 | 0.991 | 0.145 |
| Persistance | 24 | 12 | 5474.353 | 4478.274 | 9.429 | 0.527 | 1.909 |
| Naif_24h | 24 | 12 | 3694.957 | 2574.264 | 5.735 | 0.784 | 1.060 |
| Naif_168h | 24 | 12 | 5122.297 | 3232.389 | 7.122 | 0.586 | 1.271 |
| ETS | 24 | 12 | 3854.951 | 2820.476 | 6.051 | 0.765 | 1.193 |
| ARIMA | 24 | 12 | 3566.291 | 2517.634 | 5.553 | 0.799 | 1.058 |
| Persistance | 168 | 12 | 6407.197 | 5336.615 | 10.796 | 0.453 | 2.247 |
| Naif_24h | 168 | 12 | 4705.708 | 3566.111 | 7.352 | 0.705 | 1.481 |
| Naif_168h | 168 | 12 | 3640.576 | 2635.542 | 5.326 | 0.823 | 1.066 |
| ETS | 168 | 12 | 3723.393 | 2907.647 | 6.075 | 0.815 | 1.211 |
| ARIMA | 168 | 12 | 4382.618 | 3367.062 | 6.984 | 0.744 | 1.415 |

## Test final

| Modele | Horizon | N_origines | RMSE | MAE | MAPE | R_squared | MASE |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Persistance | 1 | 11 | 1859.778 | 1749.091 | 3.976 | 0.964 | 0.671 |
| Naif_24h | 1 | 11 | 1723.690 | 1302.977 | 3.222 | 0.969 | 0.533 |
| Naif_168h | 1 | 11 | 4596.575 | 3581.750 | 7.779 | 0.781 | 1.270 |
| ETS | 1 | 11 | 693.612 | 522.622 | 1.221 | 0.995 | 0.208 |
| ARIMA | 1 | 11 | 759.650 | 525.976 | 1.172 | 0.994 | 0.200 |
| Persistance | 24 | 11 | 5777.750 | 4642.388 | 9.892 | 0.628 | 1.928 |
| Naif_24h | 24 | 11 | 4694.026 | 3390.217 | 7.472 | 0.754 | 1.315 |
| Naif_168h | 24 | 11 | 5727.807 | 4351.383 | 9.424 | 0.634 | 1.586 |
| ETS | 24 | 11 | 4494.081 | 3424.153 | 7.258 | 0.775 | 1.334 |
| ARIMA | 24 | 11 | 4226.717 | 3188.539 | 6.984 | 0.801 | 1.261 |
| Persistance | 168 | 11 | 6442.960 | 5329.707 | 11.201 | 0.614 | 2.148 |
| Naif_24h | 168 | 11 | 5016.539 | 3780.641 | 8.337 | 0.766 | 1.484 |
| Naif_168h | 168 | 11 | 4299.936 | 3141.997 | 6.494 | 0.828 | 1.131 |
| ETS | 168 | 11 | 4697.762 | 3716.722 | 8.019 | 0.795 | 1.439 |
| ARIMA | 168 | 11 | 4745.763 | 3670.500 | 8.041 | 0.790 | 1.441 |

## Limites

- Évaluation rétrospective sur un instantané, sans garantie que les versions consolidées étaient disponibles à chaque origine historique.
- Seulement une semaine par mois est évaluée ; ce résultat ne couvre pas tous les jours ni tous les événements extrêmes.
- Les horaires sans décalage UTC sont interprétés en Europe/Paris. Les heures civiles ambiguës ou inexistantes sont exclues et les trous conservés ; des sources avec décalage UTC permettraient de les résoudre.
- Chaque mesure représente son intervalle de 15 ou 30 minutes, selon la cadence observée du jour. La moyenne horaire est pondérée par cette durée et exige 60 minutes de couverture.
- Aucun effet causal de météo, de calendrier ou de PIB n'est revendiqué ; les cinq modèles sont univariés.
- ETS/ARIMA : intervalles nominaux évalués en couverture et largeur dans les CSV, sans calibration supplémentaire. Pas d'intervalles inventés pour les références naïves.
- Les prévisions exportées partent de 2025-11-13 13:00:00 UTC, dernière heure complète du fichier ; ce ne sont pas des prévisions pour aujourd'hui.

## Reproduction

`Rscript EXECUTER_TOUT.R` depuis la racine, avec les mêmes sources (empreintes dans protocole.json).
Les métriques par origine, exclusions, configuration et versions R/packages sont jointes. Les données volumineuses et prédictions détaillées restent locales.
