# Classes principales et features — Première version

Ce document liste les classes essentielles de la première version jouable, leurs responsabilités et leurs interfaces. Les signatures sont données en pseudo-Dart pour fixer les contrats sans préempter les détails d'implémentation. L'objectif est qu'un agent IA puisse coder chaque classe indépendamment à partir de ces spécifications.

## 1. Couche domain — entités

### Fruit

Représente un fruit du catalogue. Identifiant stable, nom affichable, et cours unitaire dans le contexte d'une partie. Le cours est porté par l'instance car il varie d'un niveau à l'autre (et pourra fluctuer en cours de partie dans une future version).

```dart
class Fruit {
  final String id;          // "apple", "orange", etc.
  final String displayName;
  final int price;          // Cours unitaire en dollars
}
```

Égalité par identifiant. Immuable. Une méthode `copyWith` pour faciliter la mise à jour du prix lors de futures fluctuations.

### Offer

Représente une offre proposée au joueur. Type discriminé entre achat et vente via un enum, ou via deux sous-classes scellées (`sealed class Offer` avec `BuyOffer` et `SellOffer`). Les sous-classes scellées sont préférables : elles permettent un pattern matching exhaustif vérifié par le compilateur.

```dart
sealed class Offer {
  final String fruitId;
  final int quantity;
  final int totalPrice;
}

final class BuyOffer extends Offer { /* ... */ }
final class SellOffer extends Offer { /* ... */ }
```

L'offre ne connaît pas le cours du fruit ni la qualité qu'elle représente. Le calcul de qualité est effectué par le générateur ou par l'UI au moment de l'affichage si une indication visuelle est souhaitée plus tard.

### GameState

État complet d'une partie en cours, immuable. Contient les liquidités, le stock par identifiant de fruit, le dictionnaire des cours courants (pour préparer la fluctuation), le nombre de tours écoulés, le temps écoulé en millisecondes, et les offres actuellement présentées au joueur.

```dart
class GameState {
  final int cash;
  final Map<String, int> stock;          // fruitId -> quantité
  final Map<String, int> currentPrices;  // fruitId -> cours
  final int turnCount;
  final int elapsedMs;
  final List<BuyOffer> currentBuyOffers;
  final List<SellOffer> currentSellOffers;

  int get totalAssetsValue;  // cash + somme(stock[f] * currentPrices[f])
  GameState copyWith({ /* ... */ });
}
```

La méthode `totalAssetsValue` est dérivée et doit rester pure. Aucune mutation directe : tout changement passe par `copyWith`.

### LevelConfig

Configuration immuable d'un niveau, hydratée depuis un fichier JSON. Contient toutes les données nécessaires pour initialiser une partie et paramétrer la génération d'offres.

```dart
class LevelConfig {
  final String id;
  final String displayName;
  final int difficulty;
  final List<Fruit> fruits;
  final int initialCash;
  final Map<String, int> initialStock;
  final int objectiveCash;
  final double lossThresholdRatio;
  final int offersPerSide;
  final List<List<int>> buyTemplates;   // Liste de templates en %
  final List<List<int>> sellTemplates;
  final String roundingRule;            // Identifiant de la règle
}
```

### GameMode

Enum simple en première version. Peut évoluer en sealed class si chaque mode acquiert des paramètres propres.

```dart
enum GameMode { tranquille, timeLimit, timeRun }
```

### GameResult

Résultat d'une partie terminée.

```dart
sealed class GameResult {
  final int turnCount;
  final int elapsedMs;
}

final class Victory extends GameResult { /* ... */ }
final class DefeatByCollapse extends GameResult { /* ... */ }
final class DefeatByTimeout extends GameResult { /* ... */ }
```

## 2. Couche domain — moteur

### OfferGenerator

Le composant le plus important du jeu. Sa qualité détermine entièrement l'intérêt du gameplay. Doit être conçu pour être testable exhaustivement et facile à ajuster en phase de tuning.

```dart
class OfferGenerator {
  OfferGenerator({
    required RoundingRule roundingRule,
    required Random random,  // Injecté pour permettre des tests déterministes
  });

  ({ List<BuyOffer> buys, List<SellOffer> sells }) generate({
    required GameState state,
    required LevelConfig level,
  });
}
```

Algorithme général en pseudo-code :

```
1. Tirer un template d'achat parmi level.buyTemplates
2. Tirer un template de vente parmi level.sellTemplates
3. Pour chaque pourcentage du template d'achat :
     a. Choisir un fruit (rotation, aléatoire pondéré, ou stratégie ajustable)
     b. Calculer une quantité cible et un prix cible respectant le pourcentage
     c. Appliquer la règle d'arrondi pour obtenir des nombres conformes au niveau
     d. Vérifier la réalisabilité (prix <= state.cash)
     e. Si non réalisable, réduire la quantité jusqu'à l'être ou substituer
4. Idem pour les ventes (vérifier quantity <= state.stock[fruitId])
5. Mélanger l'ordre des offres dans chaque liste pour ne pas révéler la qualité
6. Retourner les deux listes
```

Points d'attention pour les tests : le générateur doit être déterministe quand on lui injecte un `Random` à seed fixe ; il ne doit jamais retourner d'offre irréalisable ; il doit toujours retourner exactement `level.offersPerSide` offres dans chaque liste ; au moins une offre rentable doit être présente du côté permettant au joueur de progresser.

### TransactionEngine

Pure fonction enveloppée dans une classe pour faciliter l'injection.

```dart
class TransactionEngine {
  GameState applyOffer(GameState state, Offer offer);
}
```

Pour un `BuyOffer` : retire `offer.totalPrice` des liquidités, ajoute `offer.quantity` au stock du fruit, incrémente le compteur de tours. Pour un `SellOffer` : ajoute `offer.totalPrice` aux liquidités, retire `offer.quantity` du stock, incrémente le compteur de tours. Aucune validation : on suppose que l'offre vient du générateur et est par construction valide.

### WinLossEvaluator

```dart
class WinLossEvaluator {
  GameResult? evaluate({
    required GameState state,
    required LevelConfig level,
    required GameMode mode,
    required int? timeLimitMs,
  });
}
```

Retourne `null` si la partie continue. Retourne une `Victory` si `state.cash >= level.objectiveCash`. Retourne une `DefeatByCollapse` si `state.totalAssetsValue < level.initialCash * level.lossThresholdRatio`. Retourne une `DefeatByTimeout` si le mode est chronométré et `state.elapsedMs >= timeLimitMs`. L'ordre d'évaluation est important : la victoire prime sur la défaite par effondrement, qui prime sur l'expiration du temps.

### RoundingRule

Interface abstraite avec plusieurs implémentations interchangeables, chargées par identifiant depuis la configuration de niveau.

```dart
abstract class RoundingRule {
  int roundQuantity(double rawQuantity);
  int roundPrice(double rawPrice);
}

class MultiplesOfTenRule implements RoundingRule { /* ... */ }
class MultiplesOfFiveRule implements RoundingRule { /* ... */ }
class IntegersUpToTwentyRule implements RoundingRule { /* ... */ }
class FreeIntegersRule implements RoundingRule { /* ... */ }
```

Une fabrique simple `RoundingRule.fromId(String id)` permet au repository de niveaux de résoudre l'identifiant lu dans le JSON.

## 3. Couche domain — repositories (interfaces)

```dart
abstract class LevelRepository {
  Future<List<LevelConfig>> loadAllLevels();
  Future<LevelConfig> loadLevel(String id);
}

abstract class ScoreRepository {
  Future<int?> getBestScore(String levelId, GameMode mode);
  Future<void> saveScore(String levelId, GameMode mode, int score);
}
```

Le score est un entier dont la sémantique dépend du mode (nombre de tours pour tranquille, temps en millisecondes pour les modes chronométrés). La comparaison « meilleur » est faite côté presentation car elle dépend de cette sémantique.

## 4. Couche data — implémentations

### LevelRepositoryImpl

Charge `assets/levels/levels_index.json` qui liste les identifiants de niveau disponibles, puis charge à la demande chaque fichier de niveau via `rootBundle.loadString`. Parse le JSON via un `LevelDto` intermédiaire qui valide la structure et convertit en `LevelConfig` du domain. Met les niveaux en cache mémoire après le premier chargement.

### ScoreRepositoryImpl

Wrapper minimal autour de `SharedPreferences`. Convention de clé : `score_${levelId}_${mode.name}`. Lit et écrit des entiers via `getInt` / `setInt`.

### LevelDto

Classe miroir du JSON, avec un constructeur `fromJson` et une méthode `toDomain()` qui produit un `LevelConfig`. Sépare strictement le format de stockage du modèle de domaine pour qu'une évolution du JSON n'impacte pas le reste du code.

## 5. Couche presentation — providers Riverpod

### Providers de repositories

```dart
final levelRepositoryProvider = Provider<LevelRepository>(
  (ref) => LevelRepositoryImpl(),
);

final scoreRepositoryProvider = Provider<ScoreRepository>(
  (ref) => ScoreRepositoryImpl(),
);
```

### Provider de la liste des niveaux

```dart
final allLevelsProvider = FutureProvider<List<LevelConfig>>((ref) async {
  return ref.watch(levelRepositoryProvider).loadAllLevels();
});
```

### GameNotifier

Le notifier central. Famille paramétrée par un objet `GameSession` qui combine `levelId` et `GameMode`.

```dart
class GameSession {
  final String levelId;
  final GameMode mode;
}

class GameNotifier extends FamilyNotifier<GameState, GameSession> {
  late final LevelConfig _level;
  late final OfferGenerator _generator;
  late final TransactionEngine _transaction;
  late final WinLossEvaluator _evaluator;

  @override
  GameState build(GameSession session) {
    // Charger le niveau, initialiser les engines, retourner l'état initial
    // avec les premières offres déjà générées
  }

  void selectOffer(Offer offer) {
    // Appliquer la transaction, évaluer la fin, regénérer les offres
    // ou émettre un état terminal
  }

  void tick(int deltaMs) {
    // Pour les modes chronométrés : avancer elapsedMs, réévaluer
  }

  void restart() {
    // Réinitialiser à l'état initial
  }
}

final gameNotifierProvider =
    NotifierProvider.family<GameNotifier, GameState, GameSession>(
  GameNotifier.new,
);
```

Le notifier ne contient aucune logique métier propre : il orchestre les composants du domain et expose un état immuable. Cette discipline garantit que les tests du domain couvrent l'essentiel et que le notifier lui-même ne nécessite que des tests d'intégration légers.

### Provider de meilleur score

```dart
final bestScoreProvider = FutureProvider.family<int?, GameSession>(
  (ref, session) async {
    return ref.watch(scoreRepositoryProvider)
              .getBestScore(session.levelId, session.mode);
  },
);
```

## 6. Couche presentation — écrans

### MainMenuScreen

Trois boutons : Jouer (mène à `LevelSelectScreen`), Paramètres (placeholder), Quitter. Aucune logique.

### LevelSelectScreen

Liste les niveaux via `allLevelsProvider`. Chaque entrée affiche le nom, la difficulté, et le meilleur score actuel. Tapper un niveau ouvre un sélecteur de mode puis navigue vers `GameScreen` avec la `GameSession` correspondante.

### GameScreen

Écran principal. Consomme `gameNotifierProvider(session)`. Disposition verticale :

- En haut, un `AccountHeader` avec liquidités, valeur totale des actifs, bouton paramètres, et éventuellement `TimerDisplay` selon le mode.
- En dessous, une `OfferGrid` des offres d'achat (`state.currentBuyOffers`).
- Au milieu, un `StockPanel` détaillant pour chaque fruit du niveau le stock courant et le cours courant.
- En bas, une `OfferGrid` des offres de vente (`state.currentSellOffers`).

Pour les modes chronométrés, un `Ticker` (basé sur `Stream.periodic` ou un `Timer`) appelle `tick` à intervalle régulier. L'écoute de l'état détecte les `GameResult` non nuls (à porter dans le state ou via un second provider) et navigue vers `GameOverScreen`.

### GameOverScreen

Affiche le résultat (victoire ou défaite, cause), le score réalisé, l'éventuel meilleur score battu, et propose Rejouer ou Retour au menu.

## 7. Couche presentation — widgets

### AccountHeader

Stateless. Affiche `cash`, `totalAssetsValue`, et un bouton paramètres. Style minimal en première version.

### OfferGrid

Stateless, paramétré par une liste d'offres et un callback `onSelect`. Construit une grille de `OfferCard`. Le nombre de colonnes s'adapte au nombre d'offres (2 colonnes par défaut).

### OfferCard

Stateless, paramétré par une offre et le `Fruit` correspondant (résolu en amont via le `LevelConfig`). Affiche : « Acheter 20 pommes pour 30 \$ » ou « Vendre 10 oranges pour 60 \$ ». Tap déclenche le callback du parent.

### StockPanel

Stateless, paramétré par le stock et les cours courants. Affiche une ligne par fruit : nom, quantité possédée, cours unitaire.

### TimerDisplay

Stateless, paramétré par le temps restant ou le temps écoulé selon le mode. Affichage simple en première version.

## 8. Périmètre minimal de la première version jouable

Pour qu'une première version mérite d'être jouée et testée, le périmètre suivant suffit :

Le mode Tranquille fonctionne de bout en bout sur un seul niveau (deux fruits, calculs simples). Le mode Time Run fonctionne également pour valider la mécanique de chronomètre. Trois niveaux jouables sont fournis pour valider que l'ajout d'un niveau ne demande qu'un fichier JSON. Les meilleurs scores sont sauvegardés et affichés sur l'écran de sélection. L'écran de jeu est lisible mais sans polish visuel. Les tests unitaires couvrent le `OfferGenerator`, le `TransactionEngine` et le `WinLossEvaluator` à au moins quatre-vingts pour cent.

Le mode Time Limit, les paramètres, les animations, les sons, et tout polish graphique sont reportés à la phase suivante.

## 9. Ordre de développement recommandé

L'ordre suivant minimise les dépendances bloquantes et permet de tester chaque couche avant d'attaquer la suivante.

D'abord les entités du domain (`Fruit`, `Offer`, `GameState`, `LevelConfig`, `GameMode`, `GameResult`), purement passives. Ensuite les règles d'arrondi et le `TransactionEngine`, simples et entièrement testables. Puis le `WinLossEvaluator`, également simple. Puis le `OfferGenerator`, qui mérite une attention particulière et des tests exhaustifs. À ce stade, toute la logique métier est validée sans une seule ligne d'UI.

Ensuite la couche data : `LevelDto`, `LevelRepositoryImpl`, et un premier fichier `level_01.json`. Vérifier que le chargement fonctionne via un test ou un petit script.

Ensuite la couche presentation : `GameNotifier` avec ses tests, puis les widgets de bas en haut (`OfferCard`, `OfferGrid`, `StockPanel`, `AccountHeader`), puis l'assemblage dans `GameScreen`. Ajouter `MainMenuScreen` et `LevelSelectScreen` en dernier pour avoir une boucle complète.

Enfin le `ScoreRepositoryImpl` et l'affichage des meilleurs scores, qui sont la cerise sur le gâteau de la première version.
