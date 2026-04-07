# Game Design Document — Fruit Trader (titre provisoire)

## 1. Pitch

Jeu mobile de calcul mental déguisé en simulation de marché. Le joueur achète et vend des fruits pour atteindre un objectif financier, en sélectionnant la meilleure offre parmi celles proposées à chaque tour. La compétence centrale est l'évaluation rapide d'un rapport prix/quantité par rapport à un cours de référence. Plate-forme cible : Android, Flutter.

## 2. Boucle de gameplay

Une partie se déroule en tours. À chaque tour, le joueur voit son état financier (liquidités, stock par fruit, valeur totale des actifs) et un ensemble d'offres : achats en haut de l'écran, ventes en bas. Il choisit une offre, la transaction est appliquée, un nouveau tour commence avec de nouvelles offres générées en fonction du nouvel état. La partie se termine lorsque l'objectif est atteint (victoire) ou lorsqu'une condition de défaite est déclenchée.

Le joueur ne peut jamais passer son tour : choisir est l'acte de jeu central. La génération d'offres garantit que toutes les offres présentées sont réalisables compte tenu de l'état courant (jamais d'achat dépassant les liquidités, jamais de vente dépassant le stock disponible).

## 3. État du joueur

L'état d'une partie en cours comprend les liquidités en dollars, un stock entier pour chaque fruit actif au niveau, et un compteur de tours écoulés. La valeur totale des actifs est dérivée : liquidités plus somme des stocks valorisés au cours courant de chaque fruit. Cette valeur totale est affichée en permanence et constitue le principal indicateur de performance immédiate, mais elle n'est pas la condition de victoire.

## 4. Conditions de fin de partie

**Victoire** : les liquidités atteignent ou dépassent le seuil objectif fixé par le niveau. Ce choix force une stratégie de liquidation au moment opportun et empêche le joueur de gagner passivement par appréciation du stock.

**Défaite par effondrement** : la valeur totale des actifs tombe en dessous d'un seuil, par exemple cinquante pour cent de la valeur initiale. Ce seuil sert de filet de sécurité pédagogique : si le joueur prend trop de mauvaises décisions, la partie s'arrête avant qu'il ne s'enfonce davantage.

**Défaite par expiration** : dans les modes chronométrés, l'épuisement du temps imparti termine la partie sans victoire.

Note de design : si une catégorie d'actif devient critique (liquidités très basses ou stock très bas), le générateur d'offres doit naturellement proposer davantage d'offres de l'autre catégorie pour permettre au joueur de se rééquilibrer. Cette propriété est garantie par le filtre de réalisabilité plutôt que par une règle explicite.

## 5. Fruits

Six fruits sont définis dans le jeu : pomme, orange, banane, cerise, abricot, raisin. Chaque niveau active un sous-ensemble (deux, quatre ou six fruits). Chaque fruit possède un cours unitaire en dollars, fixé au début de la partie par le niveau. En version initiale les cours sont constants pendant toute la partie ; le moteur est conçu pour permettre une fluctuation ultérieure sans refonte.

## 6. Offres

Une offre est un échange entre une quantité d'un fruit et un montant en dollars. Une offre d'achat propose au joueur d'acquérir N unités d'un fruit pour P dollars. Une offre de vente propose de céder N unités d'un fruit contre P dollars. La qualité d'une offre se mesure par comparaison avec le cours de référence : une offre d'achat est avantageuse si son prix unitaire effectif est inférieur au cours, une offre de vente l'est si son prix unitaire effectif est supérieur.

À chaque tour, le moteur présente quatre offres d'achat et quatre offres de vente (deux et deux dans les niveaux les plus simples). Chaque ensemble d'offres respecte un template de qualité défini par le niveau : par exemple un template `[80, 90, 95, 110]` pour les achats signifie qu'une offre est à quatre-vingts pour cent du cours (excellente), deux à quatre-vingt-dix et quatre-vingt-quinze (moyennes), une à cent-dix (mauvaise). Plusieurs templates peuvent être associés à un niveau et tirés aléatoirement à chaque tour pour éviter la répétition.

Le générateur d'offres applique deux contraintes additionnelles aux templates : les arrondis doivent respecter les règles de difficulté du niveau (chiffres ronds en facile, quelconques en difficile), et toutes les offres générées doivent être réalisables en l'état (sinon elles sont remplacées par une offre alternative plus modeste mais cohérente).

## 7. Niveaux

Un niveau est défini par un fichier de données contenant : la liste des fruits actifs et leur cours, le capital de départ en liquidités, le stock initial par fruit, l'objectif en liquidités, le seuil de défaite, le nombre d'offres affichées, les templates de qualité pour les achats et les ventes, et les règles d'arrondi pour la génération des prix et quantités.

La version initiale embarque un petit nombre de niveaux jouables. Le tuning fin et l'ajout de niveaux supplémentaires interviennent en phase d'amélioration. L'architecture doit garantir que l'ajout d'un niveau ne nécessite aucune modification de code.

## 8. Modes de jeu

Trois modes sont prévus :

**Tranquille** : aucune contrainte de temps. Le score est le nombre de tours nécessaires pour atteindre l'objectif. Mode d'apprentissage et d'entraînement.

**Time limit** : chaque tour est limité à une durée fixe (typiquement dix secondes). Si le joueur ne choisit pas, une offre par défaut est appliquée ou une pénalité est infligée (à arbitrer en phase de tuning). Le score reste le nombre de tours.

**Time run** : pas de limite par tour, mais une limite globale sur la durée totale de la partie. Le score est le temps restant à la victoire, ou la valeur des actifs atteinte avant expiration.

L'architecture doit permettre l'ajout d'un nouveau mode sans modifier les modes existants.

## 9. Score et persistance

Le meilleur score par couple (niveau, mode) est stocké localement. Aucun classement en ligne en version initiale. La persistance utilise un mécanisme simple (SharedPreferences ou Hive) afin de pouvoir évoluer ultérieurement vers une sauvegarde de progression plus riche (niveaux débloqués, statistiques détaillées).

## 10. Interface

Un seul écran de jeu, organisé verticalement. La zone supérieure regroupe les informations de compte (liquidités, valeur totale, accès aux paramètres) et la grille des offres d'achat. La zone inférieure regroupe le stock détaillé avec le cours courant de chaque fruit et la grille des offres de vente. Le menu principal et l'écran de sélection de niveau et de mode sont distincts.

L'objectif visuel de la première version est la lisibilité fonctionnelle. Le polish graphique (thème, animations, illustrations des fruits) intervient en phase ultérieure et ne doit pas être anticipé dans le code de la première version au-delà de l'usage de widgets stylables.

## 11. Hors périmètre de la première version

Sont explicitement exclus de la première version : la fluctuation des cours en cours de partie, le système de progression par déblocage, les statistiques détaillées, les achievements, les sons et musiques, les animations de transition, le multijoueur, les classements en ligne, l'iOS. Tous ces éléments doivent rester possibles à ajouter sans refonte structurelle.
