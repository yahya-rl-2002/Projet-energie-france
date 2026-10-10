"""Génère le rapport comparatif Markdown et PDF depuis les résultats enregistrés.
Dépendances : pandas, numpy, matplotlib, reportlab. Aucun modèle n'est réentraîné.
Exécuter depuis la racine : python 07_Rapport/generer_comparaison_complete.py
"""
from pathlib import Path
from xml.sax.saxutils import escape
import json
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, Image, KeepTogether

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/comparaison_versions'
PDF = ROOT / 'output/pdf/Rapport_complet_comparaison_energie_france.pdf'
OUT.mkdir(parents=True, exist_ok=True)
PDF.parent.mkdir(parents=True, exist_ok=True)
D = ROOT / 'docs/resultats_corriges'
val, test = [pd.read_csv(D / f'metriques_{phase}.csv') for phase in ['validation', 'test']]
monthly = pd.read_csv(D / 'metriques_par_origine_test.csv')
old = pd.read_csv(OUT / 'ancien_classement.csv')
manifest = json.loads((D / 'protocole.json').read_text())
if manifest['genere_utc'] != '2026-10-09 11:57:31 UTC':
    raise RuntimeError('Ce rapport analyse le calcul du 9 octobre 2026. Actualiser son analyse avant de le régénérer avec un autre calcul.')
labels = {'Persistance': 'Persistance', 'Naif_24h': 'Naïf 24 h', 'Naif_168h': 'Naïf 168 h', 'ETS': 'ETS', 'ARIMA': 'ARIMA', 'ARIMA_auto': 'ARIMA auto', 'TBATS': 'TBATS'}
def fr(x, n=2):
    if pd.isna(x): return 'Non défini'
    return f'{x:,.{n}f}'.replace(',', ' ').replace('.', ',')
def row(m, h, phase=test): return phase[(phase.Modele == m) & (phase.Horizon == h)].iloc[0]
a24, n24 = row('ARIMA', 24), row('Naif_24h', 24)
gain = 100 * (1 - a24.RMSE/n24.RMSE)
pivot = monthly[monthly.Horizon == 24].pivot(index='Origine', columns='Modele', values='RMSE')
assert len(pivot) == 11
assert np.isclose(a24.RMSE, np.sqrt(np.mean(pivot.ARIMA**2)))
wins = int((pivot.ARIMA < pivot.Naif_24h).sum())
# Graphiques exclusivement à protocole constant, sans juxtaposition trompeuse ancien/nouveau.
plt.rcParams.update({'font.family': 'DejaVu Sans', 'font.size': 9, 'axes.spines.top': False, 'axes.spines.right': False})
fig, axes = plt.subplots(1, 3, figsize=(9.2, 3.0), layout='constrained')
for ax, h in zip(axes, [1, 24, 168]):
    part = test[test.Horizon == h].sort_values('RMSE', ascending=False)
    ax.barh([labels[m] for m in part.Modele], part.RMSE, color=['#1e6091' if m == 'ARIMA' else '#8baabb' for m in part.Modele])
    ax.set_title(f'Pas 1 à {h} h')
    ax.set_xlabel('RMSE en MW')
    ax.grid(axis='x', alpha=.15)
fig.savefig(OUT / 'rmse_par_horizon.png', dpi=180)
plt.close(fig)
fig, ax = plt.subplots(figsize=(9.2, 3.2), layout='constrained')
month_labels = ['Janv.', 'Févr.', 'Mars', 'Avril', 'Mai', 'Juin', 'Juil.', 'Août', 'Sept.', 'Oct.', 'Nov.']
x = np.arange(len(pivot))
ax.plot(x, pivot.ARIMA, 'o-', label='ARIMA', color='#1e6091', linewidth=2)
ax.plot(x, pivot.Naif_24h, 's--', label='Naïf 24 h', color='#b07136', linewidth=1.5)
ax.set_xticks(x, month_labels)
ax.set_ylabel('RMSE en MW')
ax.set_xlabel('Première journée UTC du mois en 2025')
ax.set_ylim(0, max(pivot.ARIMA.max(), pivot.Naif_24h.max()) * 1.08)
ax.legend(frameon=False, ncol=2)
ax.grid(axis='y', alpha=.2)
fig.savefig(OUT / 'rmse_mensuelle_24h.png', dpi=180)
plt.close(fig)
fig, ax = plt.subplots(figsize=(9.2, 2.5), layout='constrained')
x = np.arange(3)
for j, (model, color) in enumerate([('ETS', '#8baabb'), ('ARIMA', '#1e6091')]):
    values = [row(model, h).Couverture95 for h in [1, 24, 168]]
    ax.bar(x + (j-.5)*.32, values, width=.32, label=model, color=color)
ax.axhline(95, color='#a44b37', linestyle='--', label='Niveau nominal 95 %')
ax.set_xticks(x, ['1 h', '1 à 24 h', '1 à 168 h'])
ax.set_ylabel('Couverture observée en %')
ax.set_ylim(0, 108)
ax.legend(frameon=False, ncol=3, loc='upper center', bbox_to_anchor=(.5, 1.23))
fig.savefig(OUT / 'couverture_intervalles.png', dpi=180)
plt.close(fig)

# Un seul contenu alimente les deux formats.
pages = []
def page(title, blocks): pages.append((title, blocks))
def p(text): return ('p', text)
def h(text): return ('h', text)
def table(headers, rows, widths=None): return ('table', headers, rows, widths)
def image(name, caption, height): return ('image', name, caption, height)
def numeric_table(frame):
    return table(['H (h)', 'Modèle', 'RMSE MW', 'MAE MW', 'MAPE %', 'R²', 'MASE'],
       [[str(int(r.Horizon)), labels[r.Modele], fr(r.RMSE,1), fr(r.MAE,1), fr(r.MAPE), fr(r.R_squared,3), fr(r.MASE,3)] for _,r in frame.iterrows()], [40,83,68,68,60,53,56])

page('Comparaison des versions du projet énergie France', [
    p('Rapport complet de méthode et de résultats | Yahya Rahil | 9 octobre 2026'),
    h('Conclusion générale'),
    p('La nouvelle version corrige les défauts qui empêchaient de considérer les anciens résultats comme des prévisions horaires valides. Elle définit une grille temporelle régulière, sépare validation et test, conserve des références simples et rend les résultats traçables. Elle constitue une base de recherche reproductible, mais ne démontre pas encore une fiabilité opérationnelle sur toutes les situations.'),
    p(f'À 24 heures, ARIMA est sélectionné sur 2024 puis évalué sans nouvelle sélection sur onze origines de 2025. Sa RMSE atteint {fr(a24.RMSE,1)} MW et sa MAPE {fr(a24.MAPE)} %. Sur les mêmes cibles, la RMSE est inférieure de {fr(gain)} % à celle du naïf 24 h. Ce gain porte sur le nouveau protocole uniquement.'),
    table(['Indicateur', 'Ancienne version', 'Nouvelle version'], [
      ['Meilleur modèle affiché / retenu', 'ETS', 'ARIMA choisi sur validation à 24 h'],
      ['RMSE publiée', '7 231,00 MW', '4 226,72 MW à 24 h'],
      ['MAPE publiée', '12,79 %', '6,98 % à 24 h'],
      ['Périmètre', '500 pas irréguliers en 2023', '264 cibles horaires sur 11 dates de 2025'],
      ['Comparaison directe des scores', 'Non valable entre versions', 'Valable entre modèles du nouveau test']
    ], [133,145,150]),
    p('Les différences de niveau entre les deux colonnes ne sont pas une estimation du progrès prédictif : les cibles, la fréquence, les dates et l’horizon ont changé. Aucun pourcentage de gain ancien/nouveau n’est revendiqué.'),
    h('Trois réserves à conserver dans toute présentation'),
    p('Le naïf hebdomadaire est meilleur à 168 h ; ARIMA ne bat le naïf 24 h que sur 6 des 11 journées de test ; la couverture de son intervalle nominal à 95 % n’est que de 81,44 % sur les pas 1 à 24 h. Ces constats limitent la portée du bon classement agrégé.'),
    p('Le rapport détaille successivement les données, l’audit initial, les corrections, le protocole, les résultats, l’incertitude, les limites et la reproduction. Toutes les valeurs proviennent des fichiers du projet et des calculs décrits en fin de document.')
])
page('1 Périmètre et provenance des données', [
    p('L’objet est la prévision de la consommation électrique française exprimée en MW. Une valeur en MW décrit une puissance ; elle ne doit pas être confondue avec une énergie en MWh. Le rapport compare le dépôt initial ef8ca927 au code corrigé bc9f1338 et aux résultats générés le 9 octobre 2026.'),
    table(['Élément', 'Ancienne préparation', 'Préparation corrigée'], [
      ['Sources de travail', 'Dataset enrichi après jointures', 'Deux fichiers RTE bruts combinés'],
      ['Volume en entrée', '1 154 808 lignes du dataset', '486 446 lignes RTE'],
      ['Horodatages', '258 319 libellés distincts', '121 576 heures UTC sur la grille'],
      ['Répétitions supplémentaires', '896 489 dates répétées', 'Aucune date répétée en sortie'],
      ['Valeurs horaires complètes', 'Non établies par le protocole', '121 547 heures complètes'],
      ['Heures manquantes ou partielles', 'Pas de contrôle horaire fiable', '29 conservées comme manquantes'],
      ['Dernière heure complète', 'Non distinguée de la dernière ligne', '13 novembre 2025 à 13 h UTC']
    ], [135,143,150]),
    p('Les nombres de lignes ne mesurent pas ici la quantité d’information : retirer les répétitions et agréger des mesures infrahoraires réduit normalement le nombre de lignes. Il ne faut pas présenter cette réduction comme une perte de 90 % des données.'),
    h('Qualité et nature des sources'),
    p('Les fichiers locaux couvrent 2012 à novembre 2025. Les mesures 2012-2023 sont définitives, celles de 2024 consolidées et celles de 2025 en temps réel. RTE distingue les puissances moyennes issues des comptages des puissances instantanées temps réel. Leur nature et leur révision peuvent influencer les comparaisons entre années [S3, S4].'),
    p('228 097 lignes sources sans consommation positive exploitable sont écartées ; une partie correspond aux quarts d’heure sans consommation dans les historiques demi-horaires. Cela ne signifie pas que 228 097 heures ont été perdues. Les 30 lignes ambiguës d’automne et les 30 lignes portant une heure inexistante du printemps sont exclues explicitement.'),
    p('La grille va du 31 décembre 2011 à 23 h UTC au 13 novembre 2025 à 14 h UTC. Son début correspond au 1er janvier 2012 à 00 h en France. La dernière heure est partielle ; les prévisions exportées commencent à 14 h UTC après la dernière heure complète.')
])
page('2 Ce que mesurait réellement la première version', [
    p('La comparaison avancée transformait le dataset en série R de fréquence 24, puis conservait une ligne sur 23 pour limiter la taille à environ 50 000 valeurs. Cette extraction supprimait les attributs temporels : la fréquence devenait 1. Les intervalles réels entre valeurs restaient variables, le plus souvent 2 h 30.'),
    table(['Étape', 'Résultat observé'], [
      ['Dataset initial', '1 154 808 lignes, nombreuses dates répétées'],
      ['Après sous-échantillonnage', '50 210 valeurs, pas irrégulier'],
      ['Entraînement à 80 %', '40 168 valeurs ; dernière date 17 septembre 2023 à 14 h 30'],
      ['Évaluation utilisée', '500 premières valeurs du test, environ 53 jours'],
      ['Dates effectivement comparées', '17 septembre 2023 à 17 h 30 au 9 novembre 2023 à 21 h']
    ], [145,283]),
    table(['Modèle enregistré', 'RMSE MW', 'MAPE %', 'R²'], [[labels[r.Modele], fr(r.RMSE), fr(r.MAPE), fr(r.R_squared,3)] for _,r in old.iterrows()], [152,97,89,90]),
    p('Le score ETS a été reproduit dans R lors de l’audit. Le modèle obtenu est ETS(A,N,N), sans tendance ni saisonnalité, avec une fréquence de 1. Il s’agit donc d’un résultat arithmétiquement reproductible obtenu avec une représentation du temps inadaptée à l’objectif horaire.'),
    h('La référence simple révèle la portée du score'),
    p('Répéter la dernière consommation connue sur les mêmes 500 valeurs donne une RMSE de 7 231,06 MW, contre 7 231,00 MW pour ETS : environ 0,06 MW d’écart. Le classement ne démontrait pratiquement aucun gain face à la persistance.'),
    p('Le R² négatif indique une erreur quadratique supérieure à celle de la moyenne du test connue après coup. Il ne prouve pas, à lui seul, une infériorité à la moyenne d’entraînement. Dans l’audit, cette dernière obtenait une RMSE de 10 613,56 MW.'),
    p('Un autre ancien fichier affichait une RMSE de 5 701,57 et une MAPE de 12,02 % pour un horizon étiqueté 24. Ce fichier relevait d’un autre calcul ; ses 24 pas ne sont pas assimilables aux 24 heures régulières du nouveau test. Le présent rapport conserve cette distinction.')
])
page('3 Corrections apportées et effets attendus', [
    table(['Problème initial', 'Correction effective', 'Conséquence'], [
      ['Jointures sur des heures arrondies non uniques', 'Repartir de Date et Consommation dans les fichiers RTE', 'Éviter la multiplication des mesures'],
      ['Mesures de 15 ou 30 min traitées comme horaires', 'Moyenne pondérée et couverture de 3 600 s exigée', 'Une cible horaire définie'],
      ['Sous-échantillonnage irrégulier et fréquence perdue', 'Fenêtre contiguë de 56 jours, série de fréquence 24', 'Saisonnalité quotidienne conservée'],
      ['Validation par blocs utilisant le futur', 'Origines chronologiques ; entraînement antérieur aux cibles', 'Absence de cette fuite temporelle'],
      ['Naïfs calculés à un seul pas puis demandés à 500', 'Références directement calculées au bon horizon', 'Comparaison effective de cinq méthodes'],
      ['MASE normalisé par le test', 'Échelle saisonnière calculée sur chaque entraînement', 'Interprétation du MASE rétablie'],
      ['R² infini avec une observation', 'Valeur indéfinie rendue NA', 'Pas de faux score numérique'],
      ['Rapports et dashboard lisant des fichiers différents', 'Exports communs et lectures des seuls résultats corrigés', 'Cohérence de la présentation']
    ], [141,153,134]),
    p('Les dates sans décalage UTC sont interprétées en Europe/Paris. L’automne comporte une heure civile répétée que ces libellés ne permettent pas de distinguer avec certitude. La nouvelle version conserve les trous plutôt que d’inventer une correspondance. Les heures UTC restent régulièrement espacées.'),
    p('Les trous courts de l’entraînement, limités à six heures consécutives, sont remplis uniquement avec des valeurs passées : retard 168 h si possible, sinon 24 h, sinon la dernière valeur. Les cibles du test ne sont jamais imputées. Toute origine dont les cibles sont incomplètes est exclue pour tous les modèles.'),
    p('Cette règle corrige une cause précise de biais. Elle ne garantit pas que toutes les hypothèses du projet sont désormais satisfaites : l’historique peut être révisé, les délais de publication ne sont pas simulés et l’imputation reste une approximation explicitement comptée.')
])
page('4 Protocole de la nouvelle version', [
    h('Chronologie de la sélection et de l’évaluation'),
    p('La validation utilise douze origines en 2024. Le test final utilise onze origines de janvier à novembre 2025. À chaque origine, les 1 344 heures précédentes, soit 56 jours, servent à entraîner les modèles. Les 168 heures suivantes constituent les cibles. Les paramètres du protocole sont fixés dans config_horaire.json.'),
    p('Une origine correspond au début de la dernière heure complètement observée du mois précédent. La première cible est le premier jour du mois à 00 h UTC. Les prévisions sont produites une seule fois pour la fenêtre, sans intégrer les observations qui arrivent pendant ses sept jours. À l’origine mensuelle suivante, un nouvel entraînement utilise seulement le passé alors disponible dans l’historique.'),
    table(['Méthode', 'Prévision et hypothèses'], [
      ['Persistance', 'Répète la dernière valeur observée.'],
      ['Naïf 24 h', 'Répète le profil des 24 dernières heures.'],
      ['Naïf 168 h', 'Répète le profil des 168 dernières heures.'],
      ['ETS', 'Lissage exponentiel automatique sur une série de fréquence 24.'],
      ['ARIMA saisonnier', 'auto.arima avec fréquence 24 ; recherche pas à pas approximative ; p/q au plus 2 et P/Q au plus 1.']
    ], [122,306]),
    h('Une sélection figée avant le test'),
    p('ARIMA est choisi sur la plus faible RMSE des pas 1 à 24 de validation 2024. Le test 2025 compare les cinq méthodes, mais n’est pas utilisé pour modifier le choix ou les réglages. Aucun modèle ne peut disparaître silencieusement du classement : un échec de calcul interrompt l’exécution.'),
    p('Les horizons 1, 24 et 168 décrivent des fenêtres cumulées : à 24 h, on regroupe les erreurs des pas 1 à 24 ; on ne mesure pas seulement la vingt-quatrième heure. On obtient 288 et 264 erreurs à 24 h en validation et en test, puis 2 016 et 1 848 à 168 h. Aucune des origines prévues n’a été exclue dans cette exécution.'),
    p('Les cinq méthodes sont univariées. Aucune amélioration attribuable à la température, au PIB ou aux jours fériés n’est démontrée. Les retards 24/168 h sont définis en heures écoulées UTC ; ils ne coïncident pas toujours avec la même heure civile autour du changement d’heure. Le principe de validation par origine glissante suit [S2].')
])
page('5 Lecture des métriques et comparabilité', [
    table(['Mesure', 'Calcul et interprétation'], [
      ['RMSE en MW', 'Racine de la moyenne des erreurs au carré. Pénalise davantage les grandes erreurs. Plus faible est préférable.'],
      ['MAE en MW', 'Moyenne des erreurs absolues. Donne un ordre de grandeur directement dans l’unité de consommation.'],
      ['MAPE en %', '100 × moyenne de |observé - prévu| / observé. Une MAPE de 6,98 % ne constitue pas une précision de 93,02 %.'],
      ['R²', '1 - somme des erreurs au carré / somme des écarts à la moyenne des cibles au carré. Peut être négatif ; indéfini si la variance est nulle.'],
      ['MASE à retard 24', 'Erreur absolue divisée par la moyenne de |y(t) - y(t-24)| sur l’entraînement de chaque origine.'],
      ['Couverture et largeur', 'Part des observations à l’intérieur de l’intervalle et largeur moyenne en MW. Les deux doivent être examinées ensemble.']
    ], [110,318]),
    p('Les scores agrégés sont calculés sur toutes les erreurs de la fenêtre et de toutes les origines admissibles. La RMSE agrégée n’est pas la moyenne arithmétique des RMSE mensuelles : avec des tailles égales, elle est la racine de leur moyenne quadratique. Les observations horaires d’une même fenêtre sont dépendantes ; 264 erreurs ne signifient pas 264 essais indépendants.'),
    p('Le MASE de chaque erreur utilise l’échelle de son propre entraînement. Un MASE supérieur à 1 signifie que l’erreur normalisée dépasse cette échelle historique ; il ne signifie pas automatiquement que le naïf 24 h obtient un meilleur score sur le test considéré. Dans le nouveau test à 24 h, ARIMA a un MASE de 1,261 tout en améliorant la RMSE du naïf 24 h. Définitions générales des erreurs et de l’échelle : [S1].'),
    h('Comparaisons permises et interdites'),
    p('Il est pertinent de comparer ARIMA, ETS et les naïfs sur les mêmes origines, horizons et observations du nouveau protocole. Il est aussi pertinent de comparer les méthodes de préparation et les contrôles des deux versions. Il n’est pas pertinent de calculer un gain scientifique en divisant simplement la nouvelle RMSE par l’ancienne.'),
    p('Pour isoler l’effet d’un changement de modèle, il faudrait reconstruire deux variantes sur exactement la même grille corrigée et les mêmes fenêtres, avec des réglages décidés avant un nouveau test. Réintroduire volontairement les erreurs de données initiales ne constituerait pas une référence méthodologique valable.')
])
page('6 Résultats de validation en 2024', [
    p('Douze origines, une par mois. Les colonnes ci-dessous décrivent les mêmes cibles pour tous les modèles. La sélection du modèle s’effectue uniquement à 24 h ; les autres horizons apportent un diagnostic complémentaire.'),
    numeric_table(val),
    p('À 24 h, ARIMA obtient une RMSE de 3 566,29 MW contre 3 694,96 MW pour le naïf quotidien et 3 854,95 MW pour ETS. Il est donc retenu pour le critère fixé. Sa MAPE de 5,55 % est également la plus faible des cinq méthodes sur cette fenêtre.'),
    p('À 1 h, ARIMA a la plus faible RMSE de validation, avec 692,66 MW. À 168 h, le naïf hebdomadaire est meilleur, avec 3 640,58 MW contre 4 382,62 MW pour ARIMA. Le modèle sélectionné à 24 h n’est donc pas le meilleur à tous les horizons, même avant d’examiner le test.'),
    p('Une sélection différente par horizon pourrait être préparée à partir de la validation. Elle n’est pas implémentée par le choix actuel, qui conserve un seul modèle sélectionné à 24 h. Tout changement futur de cette politique devra être réévalué sur une période restée indépendante.')
])
page('7 Résultats du test final en 2025', [
    p('Onze origines de janvier à novembre. Les observations de décembre ne sont pas disponibles dans l’instantané. Le tableau rapporte les scores agrégés ; les détails par origine permettent d’examiner leur dispersion.'),
    numeric_table(test),
    p(f'À 24 h, ARIMA obtient une MAE de {fr(a24.MAE,1)} MW et améliore la RMSE du naïf quotidien de {fr(n24.RMSE-a24.RMSE,1)} MW, soit {fr(gain)} %. L’écart de MAPE vaut {fr(n24.MAPE-a24.MAPE)} point de pourcentage. Il s’agit d’une comparaison valide puisque les dates et les cibles sont identiques.'),
    p('Le R² agrégé d’ARIMA à 24 h vaut 0,801. Ce résultat est compatible avec une bonne restitution d’une partie de la variabilité entre les cibles évaluées, mais ne garantit pas la maîtrise des pics ni une faible erreur chaque jour. Les écarts entre saisons contribuent à la variance utilisée dans ce R².'),
    p('La RMSE ARIMA à 24 h est plus élevée sur le test que sur la validation. Ce décalage invite à ne pas extrapoler les performances de validation seules. Les scores portent sur des premières journées de mois, incluant notamment des jours particuliers, et non sur une moyenne de toutes les journées de 2025.')
])
page('8 Comparaison selon l’horizon et selon le mois', [
    image('rmse_par_horizon.png', 'Figure 1 - RMSE de test par fenêtre. Les cinq méthodes partagent le même protocole.', 154),
    p('À 1 h, ETS a la plus faible RMSE de test (693,61 MW), tandis qu’ARIMA a la plus faible MAPE (1,17 %). Il n’existe donc pas de vainqueur unique indépendant du critère. Ces constats reposent seulement sur onze premières heures de mois.'),
    p('À 168 h, le naïf hebdomadaire obtient une RMSE de 4 299,94 MW et une MAPE de 6,49 %. ARIMA obtient 4 745,76 MW et 8,04 %. La répétition du profil de la semaine précédente reste une référence forte ; la saisonnalité hebdomadaire doit être mieux prise en compte avant de privilégier ARIMA pour une semaine complète.'),
    image('rmse_mensuelle_24h.png', 'Figure 2 - Erreur sur la première journée UTC de chaque mois, pas une moyenne mensuelle.', 164),
    p(f'ARIMA bat le naïf quotidien sur {wins} des 11 journées évaluées. Son agrégat est meilleur, mais ses résultats restent hétérogènes. Les erreurs élevées de certaines fenêtres pèsent fortement dans la RMSE. Aucune significativité statistique du gain n’a été établie sur cet échantillon.')
])
page('9 Détail des journées de test à 24 heures', [
    table(['Journée UTC', 'ARIMA MW', 'Naïf 24 h MW', 'Meilleure des deux'], [
      [(pd.Timestamp(idx) + pd.Timedelta(hours=1)).strftime('%d/%m/%Y'), fr(r.ARIMA,1), fr(r.Naif_24h,1), 'ARIMA' if r.ARIMA < r.Naif_24h else 'Naïf 24 h'] for idx,r in pivot.iterrows()
    ], [102,104,112,110]),
    p('La plus forte RMSE ARIMA de ces journées apparaît le 1er janvier (6 786,64 MW), puis le 1er mai (6 401,93 MW). Ces dates suggèrent d’étudier les effets de calendrier, mais elles ne prouvent pas que le calendrier explique à lui seul les erreurs. Une analyse causale demanderait des variables et un protocole adaptés.'),
    p('La plus faible RMSE ARIMA est observée le 1er octobre (1 230,10 MW). Ce jour-là, le naïf quotidien est pourtant bien meilleur, à 402,07 MW. Une bonne erreur absolue pour un modèle ne suffit donc pas à justifier sa complexité si une référence simple fait mieux sur la même cible.'),
    p('Le résultat agrégé ne doit pas masquer les situations défavorables. Par exemple, le 1er avril et le 1er août favorisent aussi le naïf quotidien. Pour décider d’un usage opérationnel, il faudrait augmenter le nombre d’origines, analyser les jours ouvrés, les week-ends et les jours fériés, puis examiner séparément les périodes de fortes consommations.'),
    h('Ce qu’on peut conclure'),
    p('Sur les onze journées disponibles, le choix ARIMA décidé en validation produit la meilleure RMSE agrégée à 24 h parmi les cinq méthodes testées. On ne peut pas en déduire qu’il est meilleur chaque jour, ni qu’il le restera sur une nouvelle année. Une prochaine évaluation plus dense devra conserver un test indépendant pour éviter de transformer progressivement 2025 en jeu de réglage.')
])
page('10 Incertitude et couverture des intervalles', [
    table(['Fenêtre', 'Modèle', 'Couverture 80 %', 'Couverture 95 %', 'Largeur 95 % MW'], [
      [f'1 à {h0} h', m, fr(row(m,h0).Couverture80,1)+' %', fr(row(m,h0).Couverture95,1)+' %', fr(row(m,h0).Largeur95,0)] for h0 in [1,24,168] for m in ['ETS','ARIMA']
    ], [66,59,100,100,103]),
    image('couverture_intervalles.png', 'Figure 3 - La ligne rouge correspond au niveau nominal de 95 %.', 137),
    p('À 24 h, ARIMA couvre 81,44 % des cibles avec son intervalle nominal à 95 % ; ETS couvre seulement 72,35 %. Les intervalles sont insuffisamment couvrants sur cet échantillon. Le bon classement des prévisions ponctuelles ne justifie pas de les présenter comme des bandes de risque correctement calibrées.'),
    p('À 168 h, les couvertures se rapprochent du niveau nominal : 95,67 % pour ARIMA et 94,81 % pour ETS. Toutefois, leurs largeurs moyennes atteignent respectivement 23 441 MW et 29 715 MW. Une forte couverture obtenue grâce à des bandes très larges ne suffit pas à démontrer une précision utile.'),
    p('À 1 h, une seule observation de plus ou de moins change la couverture d’environ 9,1 points, car il n’y a que onze origines. Les couvertures à plusieurs heures utilisent davantage de points, mais ceux d’une même fenêtre sont dépendants. Aucun intervalle d’incertitude sur ces taux n’est revendiqué.'),
    p('La prochaine étape est une calibration sur un jeu distinct, suivie d’une évaluation hors échantillon par horizon et par type de journée. Les références naïves n’ont pas reçu d’intervalles artificiels : leur absence est indiquée dans les CSV.')
])
page('11 Limites et prochaines améliorations', [
    h('État réel du projet'),
    p('Le projet est désormais cohérent pour une étude rétrospective de séries temporelles. Les principaux défauts identifiés dans la première version ont été corrigés. Une utilisation pour des décisions de gestion du réseau, de trading ou d’engagement contractuel nécessiterait une validation et une supervision supplémentaires ; les résultats actuels ne démontrent pas cette aptitude.'),
    table(['Priorité', 'Travail à réaliser', 'Critère de réussite'], [
      ['1', 'Évaluer des origines quotidiennes sur une nouvelle période indépendante', 'Gain stable face aux naïfs, dispersion et cas difficiles publiés'],
      ['1', 'Calibrer les intervalles sur validation séparée', 'Couverture proche du niveau nominal sans largeur excessive'],
      ['2', 'Modéliser ensemble cycles quotidiens et hebdomadaires', 'Amélioration à 168 h face au naïf hebdomadaire'],
      ['2', 'Ajouter calendrier et météo disponibles à l’origine', 'Gain hors échantillon, sans température future observée utilisée comme prévision'],
      ['2', 'Prendre en compte publications et révisions des données', 'Backtest reproduisant les informations réellement disponibles'],
      ['3', 'Surveiller fraîcheur, données absentes et dérive des erreurs', 'Alertes et règles de repli testées avant déploiement']
    ], [48,198,182]),
    p('Les timestamps historiques sans décalage UTC ne permettent pas de restituer exactement les deux occurrences de certaines heures d’automne. Les trous sont explicites, mais leur résolution demanderait une source plus précise. L’imputation causale de petits manques est préférable à une fuite d’information, tout en restant une approximation.'),
    p('Le retrait des anciennes jointures signifie que les 47 variables initialement annoncées ne sont pas utilisées par le pipeline corrigé. Celui-ci ne revendique ni SARIMAX validé, ni effet du PIB ou de la température. Les anciens scénarios multiplicatifs à plus ou moins 5 % et les tests de robustesse spécifiques ne font pas partie de la nouvelle démonstration.'),
    p('Enfin, l’instantané s’arrête en novembre 2025. Les prévisions exportées illustrent la continuation de cet historique, pas une prévision pour octobre 2026. Pour une utilisation actuelle, il faut actualiser les sources et revalider le fonctionnement.')
])
page('12 Reproduction et références', [
    h('Versions et fichiers à conserver'),
    p('Ancienne version : ef8ca92752d2db0d3de307d8eff9b5ddb2964ef1. Version corrigée analysée : bc9f1338c97f361ffc8f7b9068c35d05efea76a3. Les méthodes n’ont pas été réentraînées pour la rédaction de ce rapport ; les résultats sont ceux de l’exécution enregistrée et contrôlée.'),
    table(['Preuve', 'Emplacement dans le dépôt'], [
      ['Configuration et empreintes', 'docs/resultats_corriges/protocole.json'],
      ['Qualité des données', 'docs/resultats_corriges/qualite_donnees.json'],
      ['Scores agrégés', 'docs/resultats_corriges/metriques_validation.csv et metriques_test.csv'],
      ['Scores par origine', 'docs/resultats_corriges/metriques_par_origine_validation.csv et metriques_par_origine_test.csv'],
      ['Résultats anciens conservés', 'docs/comparaison_versions/ancien_classement.csv et ancienne_evaluation.csv'],
      ['Code avant correction', 'archives/pipeline_initial/'],
      ['Audit initial et méthode', 'docs/AUDIT_INITIAL.md et docs/METHODOLOGIE_CORRIGEE.md']
    ], [124,304]),
    p('Depuis la racine du dépôt : Rscript tests/test_pipeline_horaire.R ; Rscript tests/test_exports_horaires.R ; Rscript tests/test_dashboard.R ; Rscript EXECUTER_TOUT.R. Les dépendances et données nécessaires sont décrites dans le README. Le test du dashboard requiert shiny ; l’exécution réelle requiert les sources locales.'),
    p('Les vérifications réalisées couvrent les doublons, changements d’heure, agrégations, séparation passé/futur, métriques, prévisions naïves, exports et filtres du dashboard. Une vérification indépendante en Python a confirmé l’agrégation des 121 576 heures et les métriques exportées. Cela étaye la cohérence du calcul ; cela ne remplace pas une validation statistique sur davantage de périodes.'),
    h('Sources et documentation'),
    p('[S1] Hyndman et Athanasopoulos, Forecasting Principles and Practice, chapitre Evaluating point forecast accuracy. https://otexts.com/fpp3/accuracy.html'),
    p('[S2] Même ouvrage, chapitre Time series cross validation. https://otexts.com/fpp3/tscv.html'),
    p('[S3] RTE, téléchargement des indicateurs éCO2mix et révisions des historiques. https://www.rte-france.com/donnees-publications/eco2mix-donnees-temps-reel/telecharger-indicateurs'),
    p('[S4] RTE, Spécification des fichiers de données en puissance pour éCO2mix, version du 24 juin 2025, accessible depuis la page [S3].'),
    p('Dépôt : https://github.com/yahya-rl-2002/Projet-energie-france. Consultation des références le 9 octobre 2026. Les sources externes définissent les méthodes et les données ; les chiffres de performance proviennent des sorties du projet.')
])

# Markdown portable et consultable dans GitHub.
md=[]
for i,(title,blocks) in enumerate(pages):
    md += [('# ' if i == 0 else '## ') + title, '']
    for b in blocks:
        if b[0]=='p': md += [b[1], '']
        elif b[0]=='h': md += ['### '+b[1], '']
        elif b[0]=='table':
            md += ['| '+' | '.join(b[1])+' |','| '+' | '.join(['---']*len(b[1]))+' |']
            md += ['| '+' | '.join(map(str,r))+' |' for r in b[2]]
            md += ['']
        elif b[0]=='image': md += [f'![{b[2]}]({b[1]})','',b[2],'']
(OUT/'RAPPORT_COMPLET.md').write_text('\n'.join(md),encoding='utf-8')

# PDF avec polices embarquées et pagination maîtrisée.
fontdir=Path(matplotlib.get_data_path())/'fonts/ttf'
for name,file in [('DejaVu','DejaVuSans.ttf'),('DejaVu-Bold','DejaVuSans-Bold.ttf'),('DejaVu-Oblique','DejaVuSans-Oblique.ttf')]:
    pdfmetrics.registerFont(TTFont(name,str(fontdir/file)))
pdfmetrics.registerFontFamily('DejaVu',normal='DejaVu',bold='DejaVu-Bold',italic='DejaVu-Oblique')
styles=getSampleStyleSheet()
styles.add(ParagraphStyle(name='BodyFR',fontName='DejaVu',fontSize=9.3,leading=13.1,spaceAfter=8,splitLongWords=True))
styles.add(ParagraphStyle(name='SectionFR',fontName='DejaVu-Bold',fontSize=17,leading=22,spaceAfter=14))
styles.add(ParagraphStyle(name='TitleFR',fontName='DejaVu-Bold',fontSize=24,leading=29,spaceAfter=16))
styles.add(ParagraphStyle(name='SubFR',fontName='DejaVu-Bold',fontSize=11,leading=15,spaceBefore=7,spaceAfter=6))
styles.add(ParagraphStyle(name='CellFR',fontName='DejaVu',fontSize=8.0,leading=10.4))
styles.add(ParagraphStyle(name='HeaderFR',fontName='DejaVu-Bold',fontSize=8,leading=10.4,textColor=colors.white))
styles.add(ParagraphStyle(name='CaptionFR',fontName='DejaVu-Oblique',fontSize=7.8,leading=10.6,textColor=colors.HexColor('#4c5c66'),spaceAfter=8))

def para(text,style='BodyFR'):
    return Paragraph(escape(str(text)),styles[style])
W,H=A4
margin=55
width=W-2*margin
story=[]
for i,(title,blocks) in enumerate(pages):
    if i: story.append(PageBreak())
    story.append(para(title,'TitleFR' if i==0 else 'SectionFR'))
    for b in blocks:
        if b[0]=='p':story.append(para(b[1]))
        elif b[0]=='h':story.append(para(b[1],'SubFR'))
        elif b[0]=='image':
            story.append(KeepTogether([Image(str(OUT/b[1]),width=width,height=b[3]),para(b[2],'CaptionFR')]))
        elif b[0]=='table':
            headers,rows,widths=b[1:]
            widths=[v/sum(widths)*width for v in widths] if widths else None
            cells=[[para(c,'HeaderFR') for c in headers]]+[[para(c,'CellFR') for c in r] for r in rows]
            t=Table(cells,colWidths=widths,repeatRows=1,hAlign='LEFT')
            t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#1e4b66')),
              ('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,colors.HexColor('#f0f4f6')]),
              ('GRID',(0,0),(-1,-1),.35,colors.HexColor('#d4dce1')),
              ('VALIGN',(0,0),(-1,-1),'MIDDLE'),('LEFTPADDING',(0,0),(-1,-1),7),
              ('RIGHTPADDING',(0,0),(-1,-1),7),('TOPPADDING',(0,0),(-1,-1),6),('BOTTOMPADDING',(0,0),(-1,-1),6)]))
            story.extend([t,Spacer(1,11)])

def footer(canvas,doc):
    canvas.saveState()
    canvas.setFont('DejaVu',7.7)
    canvas.setFillColor(colors.HexColor('#5d6b74'))
    canvas.drawString(margin,H-30,'PROJET ÉNERGIE FRANCE  |  COMPARAISON ET RAPPORT COMPLET')
    canvas.drawString(margin,27,'Versions ef8ca927 et bc9f1338  -  Rapport du 9 octobre 2026')
    canvas.drawRightString(W-margin,27,str(doc.page))
    canvas.restoreState()
SimpleDocTemplate(str(PDF),pagesize=A4,rightMargin=margin,leftMargin=margin,topMargin=55,bottomMargin=48,
    title='Comparaison des versions du projet énergie France',author='Yahya Rahil',
    subject='Audit comparatif des méthodes et résultats de prévision horaire').build(story,onFirstPage=footer,onLaterPages=footer)
print(PDF)
print(OUT/'RAPPORT_COMPLET.md')
