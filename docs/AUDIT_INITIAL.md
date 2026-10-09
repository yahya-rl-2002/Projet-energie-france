# Audit des résultats — 9 octobre 2026

Le projet contient un travail substantiel de collecte, d'analyse et de présentation. Cependant, les résultats actuels ne permettent pas de valider un système de prévision horaire fiable. Les scores enregistrés sont cohérents avec les données utilisées, mais la préparation temporelle et plusieurs procédures d'évaluation doivent être corrigées.

## Périmètre et vérifications

- Dépôt : https://github.com/yahya-rl-2002/Projet-energie-france
- Commit local et distant identiques : `ef8ca92752d2db0d3de307d8eff9b5ddb2964ef1`.
- Code examiné dans `R_VERSION`, données et résultats locaux disponibles (certains sont exclus du versionnement).
- Comptage complet des dates, reproduction du découpage de la comparaison, recalcul de références simples avec Python/pandas ; réajustement d'ETS et vérifications ciblées de comportement dans R 4.4.2 et `forecast`.
- Pas de modification des scripts de production ni des résultats historiques. Aucun push GitHub.
- L'audit ne constitue pas une réexécution exhaustive de tous les modèles, collecteurs, graphiques et tests de robustesse.

## 1. Critique : le dataset n'est pas une série horaire régulière

Mesures sur `R_VERSION/data/dataset_complet.csv` :

| Vérification | Résultat |
|---|---:|
| Lignes | 1 154 808 |
| Horodatages distincts | 258 319 |
| Répétitions supplémentaires de dates | 896 489 |
| Dates avec des consommations contradictoires | 0 |
| Dates ou consommations manquantes | 0 |
| Début | 2012-01-01 00:00 |
| Fin | 2025-11-13 15:00 |

Entre horodatages distincts, 227 913 écarts sont de 30 minutes et 30 391 de 15 minutes ; 14 écarts sont plus grands. 189 918 dates apparaissent cinq fois et 68 381 trois fois. Ces répétitions ne sont pas nécessairement des lignes entièrement identiques : les métadonnées RTE peuvent changer.

`01_Donnees/combinaison_donnees.R:880-908` arrondit les dates à l'heure puis effectue une jointure avec des clés RTE non uniques, sans agrégation préalable. Ce mécanisme peut multiplier les lignes et associer des mesures de moments voisins. Il faut reconstruire une table unique par instant, choisir explicitement le fuseau horaire et agréger les puissances à une grille horaire régulière avec pondération par durée si nécessaire. Ne pas sommer des MW pour obtenir une puissance horaire.

## 2. Critique : la fréquence saisonnière disparaît et les horizons ne sont plus des heures

Dans `04_Validation/comparaison_modeles_avancee.R:475-483`, une série `ts(..., frequency=24)` est sous-échantillonnée avec `consommation_ts[indices]`. Ce sous-ensemble devient un vecteur et `frequency(...)` vaut ensuite **1**, vérifié dans R. Le même motif figure dans la validation croisée et la prévision multi-horizons.

Sur les données présentes, le code retient une ligne sur 23 : 50 210 valeurs, séparées le plus souvent de 2 h 30, parfois de 1 h, 1 h 15, 1 h 30, 3 h ou davantage. Les modèles ne reçoivent donc ni une série horaire, ni une série régulièrement espacée. Recréer simplement `frequency=24` après ce sous-échantillonnage ne suffirait pas.

Conséquences : les prévisions étiquetées 24 h, 168 h ou 720 h représentent des nombres de pas sans durée horaire garantie ; la saisonnalité journalière annoncée n'est plus configurée correctement. Pour réduire les coûts, conserver une fenêtre récente contiguë après régularisation horaire.

## 3. Élevé : le meilleur score n'apporte pratiquement rien face à la persistance

Le découpage reproduit utilise 40 168 observations d'entraînement puis les 500 premières observations du test. Dernière date d'entraînement : 2023-09-17 14:30. Fenêtre effectivement évaluée : 2023-09-17 17:30 à 2023-11-09 21:00, soit environ 53 jours, et non 500 heures.

| Méthode | RMSE (MW) | MAPE (%) | R² |
|---|---:|---:|---:|
| ETS enregistré | 7 231,0023 | 12,78811 | -0,26373 |
| Dernière valeur d'entraînement répétée, recalculée | 7 231,0627 | 12,78819 | -0,26375 |
| Moyenne d'entraînement, recalculée | 10 613,5628 | 22,29777 | -1,72256 |

Le gain de RMSE d'ETS sur la persistance est d'environ **0,06 MW**, négligeable ici. La variance des observations du test et la RMSE publiée redonnent exactement le R² enregistré pour ETS : ce n'est pas une incohérence arithmétique.

Le réajustement indépendant dans R reproduit également les scores affichés : RMSE 7 231,002, MAPE 12,78811 %, R² -0,2637256. Le modèle sélectionné est `ETS(A,N,N)`, sans tendance ni saisonnalité, sur une série de fréquence 1. Le problème tient donc au protocole et à son interprétation, pas à une impossibilité de reproduire ce score.

Un R² négatif signifie ici une erreur quadratique supérieure à celle de la moyenne **du test**, connue a posteriori. Cela ne signifie pas automatiquement que le modèle est pire que la moyenne d'entraînement : cette dernière est effectivement moins bonne dans ce cas. Une MAPE de 12,79 % n'est pas un « taux de précision de 87,21 % ».

Il manque une comparaison fiable avec la persistance et les naïfs saisonniers à 24 h et 168 h, sur une grille corrigée et plusieurs origines de prévision.

## 4. Élevé : les modèles de référence échouent dans la comparaison

`04_Validation/comparaison_modeles_avancee.R:130,140` crée `naive(...,h=1)` et `snaive(...,h=1)`, puis tente de demander 500 pas à ces objets de prévision vers la ligne 263. Dans l'environnement disponible, `forecast(naive(x,h=1),h=500)` échoue : « Please select a longer horizon when the forecasts are first computed ».

Les exceptions sont interceptées et ces références disparaissent du classement. Il faut générer directement les prévisions naïves à l'horizon évalué. La perte de fréquence explique également l'échec de `stl()` sur la série devenue non saisonnière, confirmé par un test ciblé.

## 5. Élevé : la validation par blocs utilise des données futures

`04_Validation/validation_croisee.R:250-264` retire le bloc test puis concatène les observations antérieures **et postérieures** pour entraîner le modèle. Il prédit ensuite après cette série concaténée et compare au bloc retiré : les prévisions ne correspondent pas aux dates évaluées.

De plus, les expressions `1:0` et `(n+1):n` ne sont pas vides en R : aux blocs extrêmes, les indices peuvent réintroduire une observation du test dans l'entraînement.

La validation temporelle à fenêtre croissante du même fichier est mieux conçue dans son principe, mais hérite de la série irrégulière. Refaire l'évaluation en utilisant exclusivement le passé à chaque origine. Référence : [Hyndman et Athanasopoulos, validation temporelle](https://otexts.com/fpp3/tscv.html).

## 6. Moyen : certaines métriques et interprétations sont incorrectes

- Dans `05_Prevision/evaluation_previsions.R:100-104` et `04_Validation/comparaison_modeles_avancee.R:177-181`, le dénominateur du MASE est calculé avec `diff(obs)` sur **le test**. Le MASE standard utilise les erreurs naïves sur **l'entraînement**, avec un retard saisonnier explicite si pertinent. L'interprétation du rapport comme comparaison à un naïf saisonnier n'est donc pas justifiée. Voir [la définition du MASE](https://otexts.com/fpp3/accuracy.html).
- Le CSV d'évaluation affiche `R_squared=-Inf` à l'horizon 1 : avec une seule observation, la variance est nulle et le R² est indéfini. Il faut retourner `NA`, puis agréger les erreurs de nombreuses origines pour juger la prévision à une heure.
- Les évaluations par horizon utilisent une seule origine et les préfixes du même test. Ce ne sont pas des performances moyennes sur de multiples prévisions quotidiennes.
- Une couverture de 100 % ne prouve pas la bonne calibration d'un intervalle nominal à 95 %. La validation enregistrée indique une largeur moyenne de 29 413 MW : il faut analyser conjointement largeur et couverture sur plusieurs périodes.

## 7. Moyen : les conclusions dépassent ce qui est démontré

- Le classement final contient seulement ETS, ARIMA_auto et TBATS. La fonction de comparaison avancée ne teste pas SARIMAX ; l'existence d'un SARIMAX avec température dans un autre script ne démontre pas un gain dans ce classement.
- Le dataset local comporte 47 colonnes, mais aucune colonne PIB, chômage ou inflation. Leur utilisation dans les résultats affichés n'est donc pas établie.
- `05_Prevision/analyse_scenarios.R:79-100,157-159` applique des multiplicateurs 0,95 / 1 / 1,05. Ce sont des hypothèses illustratives, pas des probabilités estimées ni des effets causaux de météo ou d'économie.

## Ordre de correction conseillé

1. Reconstruire une série horaire unique, ordonnée et régulière ; contrôler fuseaux, changements d'heure, trous, jointures et valeurs manquantes.
2. Garder les dates avec chaque observation et chaque prévision ; supprimer le sous-échantillonnage irrégulier.
3. Séparer chronologiquement entraînement, validation et test final ; refaire plusieurs origines de prévision aux vrais horizons 1 h, 24 h et 168 h.
4. Comparer aux naïfs à dernière valeur, à 24 h et à 168 h, puis à ETS et aux modèles saisonniers.
5. Corriger MASE, R² dégénéré et intervalles ; expliciter les données exogènes réellement disponibles au moment de prévoir.
6. Régénérer les résultats, graphiques et conclusions uniquement après ces corrections.

Le projet est une base exploitable pour un travail de séries temporelles. Les résultats actuels doivent être présentés comme exploratoires, avec ces limites explicites ; leur présentation comme prévisions horaires validées n'est pas défendable en l'état.
