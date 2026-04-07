# Architecture technique — Fruit Trader

## 1. Choix technologiques

**Framework** : Flutter, cible Android uniquement en première version.

**Langage** : Dart 3.x avec sound null safety. Records et pattern matching exploités là où ils clarifient le code.

**Gestion d'état** : Riverpod 2.x. Préféré à Bloc pour ce projet en raison de sa concision, de sa testabilité immédiate (overrides triviaux) et de sa séparation naturelle entre état immuable et notificateurs. Préféré à Provider pour sa sécurité de type et son meilleur outillage. La taille modeste du projet ne justifie pas la verbosité de Bloc.

**Persistance locale** : `shared_preferences` en première version. Suffisant pour stocker des meilleurs scores sous forme clé-valeur. Une migration vers Hive ou Isar reste possible si la structure de progression devient riche, mais ne doit pas être anticipée.

**Données de niveaux** : fichiers JSON embarqués dans les assets de l'application, chargés au démarrage. Format JSON choisi pour sa lisibilité, sa facilité d'édition manuelle et l'absence de dépendance à un parseur tiers (le décodeur est dans la bibliothèque standard de Dart).

**Tests** : `flutter_test` pour les widgets, `test` pour la logique pure. Le moteur de génération d'offres et toute la couche domain doivent être testables sans Flutter (pas d'import de `package:flutter`).

**Pas de dépendances tierces non listées** en première version. Chaque ajout de dépendance future devra être justifié.

## 2. Patterns architecturaux

L'architecture suit une séparation en trois couches inspirée de Clean Architecture, mais sans son formalisme excessif.

La couche **domain** contient les entités du jeu (état, fruit, offre, niveau, résultat de partie), les règles métier pures (calcul de la valeur des actifs, application d'une transaction, génération d'offres, évaluation des conditions de fin) et les interfaces abstraites (repositories). Elle ne dépend de rien : ni de Flutter, ni de Riverpod, ni de la couche data. Elle est entièrement testable en Dart pur.

La couche **data** implémente les repositories définis par le domain. Elle contient le chargement des niveaux depuis les assets JSON et la persistance des scores via shared_preferences. C'est la seule couche autorisée à connaître les formats de stockage et les chemins d'assets.

La couche **presentation** contient les widgets Flutter, les notifiers Riverpod qui exposent l'état du jeu à l'UI, et la logique de navigation. Elle dépend du domain (qu'elle utilise via les notifiers) et n'a aucune connaissance directe de la couche data.

Les dépendances pointent toujours vers le domain : data dépend de domain, presentation dépend de domain, et l'injection des implémentations data dans la presentation se fait via Riverpod au point de composition (les providers de plus haut niveau).

## 3. Structure des dossiers

```
fruit_trader/
├── android/                      # Configuration Android (généré par Flutter)
├── assets/
│   ├── levels/                   # Fichiers JSON des niveaux
│   │   ├── level_01.json
│   │   ├── level_02.json
│   │   └── levels_index.json     # Index listant les niveaux disponibles
│   └── fruits/                   # Métadonnées des fruits (nom localisé, future icône)
│       └── fruits.json
├── lib/
│   ├── main.dart                 # Point d'entrée, ProviderScope, MaterialApp
│   │
│   ├── domain/                   # Logique métier pure, aucun import Flutter
│   │   ├── entities/
│   │   │   ├── fruit.dart
│   │   │   ├── offer.dart
│   │   │   ├── game_state.dart
│   │   │   ├── level_config.dart
│   │   │   ├── game_mode.dart
│   │   │   └── game_result.dart
│   │   ├── engine/
│   │   │   ├── offer_generator.dart       # Cœur du jeu : génération des offres
│   │   │   ├── transaction_engine.dart    # Application d'une offre à un état
│   │   │   ├── win_loss_evaluator.dart    # Conditions de fin de partie
│   │   │   └── rounding_rules.dart        # Règles d'arrondi par niveau
│   │   └── repositories/
│   │       ├── level_repository.dart      # Interface abstraite
│   │       └── score_repository.dart      # Interface abstraite
│   │
│   ├── data/                     # Implémentations concrètes des repositories
│   │   ├── level_repository_impl.dart     # Charge les JSON depuis assets
│   │   ├── score_repository_impl.dart     # Lit/écrit dans shared_preferences
│   │   └── dto/
│   │       └── level_dto.dart             # Mapping JSON ↔ LevelConfig
│   │
│   ├── presentation/
│   │   ├── providers/                     # Providers Riverpod
│   │   │   ├── repositories_providers.dart
│   │   │   ├── level_providers.dart
│   │   │   ├── game_providers.dart        # GameNotifier, état de la partie en cours
│   │   │   └── score_providers.dart
│   │   ├── screens/
│   │   │   ├── main_menu_screen.dart
│   │   │   ├── level_select_screen.dart
│   │   │   ├── game_screen.dart           # L'écran de jeu unique
│   │   │   └── game_over_screen.dart
│   │   ├── widgets/
│   │   │   ├── account_header.dart        # Liquidités, valeur totale, paramètres
│   │   │   ├── offer_grid.dart            # Grille générique d'offres
│   │   │   ├── offer_card.dart            # Carte d'une offre individuelle
│   │   │   ├── stock_panel.dart           # Stock détaillé avec cours
│   │   │   └── timer_display.dart         # Affichage du chrono (modes temps)
│   │   └── theme/
│   │       └── app_theme.dart             # Thème Flutter, à enrichir plus tard
│   │
│   └── core/                     # Utilitaires transverses
│       ├── result.dart                    # Type Result<T, E> pour erreurs typées
│       └── extensions.dart                # Extensions utilitaires
│
└── test/
    ├── domain/
    │   ├── engine/
    │   │   ├── offer_generator_test.dart  # Tests critiques du générateur
    │   │   ├── transaction_engine_test.dart
    │   │   └── win_loss_evaluator_test.dart
    │   └── entities/
    └── presentation/
        └── game_providers_test.dart
```

## 4. Modules et responsabilités

### Module domain/engine

C'est le cœur fonctionnel du jeu. Quatre composants strictement indépendants les uns des autres pour faciliter les tests et les évolutions futures.

Le **générateur d'offres** prend en entrée l'état courant du jeu et la configuration du niveau, et produit en sortie une liste d'offres d'achat et une liste d'offres de vente. Il consulte les templates de qualité du niveau, applique les règles d'arrondi, vérifie la réalisabilité de chaque offre par rapport à l'état (liquidités pour les achats, stock pour les ventes), et substitue toute offre irréalisable par une variante équivalente plus modeste. Ce composant doit exposer une interface stable car il est appelé à chaque tour et sera celui dont les paramètres seront le plus souvent ajustés en phase de tuning.

Le **moteur de transaction** prend un état et une offre choisie, et retourne un nouvel état (immuable). Il ne valide pas la légitimité de l'offre — cette responsabilité incombe au générateur — mais il garantit la cohérence arithmétique de la transaction.

L'**évaluateur de fin de partie** prend un état et la configuration de mode, et retourne soit `null` (la partie continue), soit un `GameResult` indiquant victoire ou défaite avec sa cause.

Les **règles d'arrondi** encapsulent la logique de génération de prix et de quantités conformes au profil de difficulté du niveau (multiples de dix, multiples de cinq, entiers quelconques, etc.). Elles sont injectées dans le générateur d'offres.

### Module domain/repositories

Deux interfaces minimales. Le `LevelRepository` expose `loadAllLevels()` et `loadLevel(id)`. Le `ScoreRepository` expose `getBestScore(levelId, mode)` et `saveScore(levelId, mode, score)`. Aucune méthode au-delà du strict nécessaire pour la première version.

### Module data

Implémente les deux repositories. Le `LevelRepositoryImpl` lit les fichiers JSON depuis `rootBundle`, les parse via les DTO, et les transforme en `LevelConfig` du domain. Le `ScoreRepositoryImpl` utilise `SharedPreferences` avec une convention de clés du type `score_<levelId>_<mode>`.

### Module presentation/providers

Le provider central est le `GameNotifier`, un `Notifier` Riverpod paramétré par la configuration de partie (niveau et mode). Il expose un `GameState` immuable enrichi des offres courantes. Ses méthodes publiques sont `selectOffer(offer)`, `tick()` (pour les modes chronométrés), et `restart()`. Toute modification d'état passe par lui et reste pure : il appelle le moteur de transaction, demande une nouvelle génération d'offres, évalue les conditions de fin, et émet un nouvel état.

Les autres providers exposent les listes de niveaux disponibles et les meilleurs scores, avec mise en cache automatique via `FutureProvider` ou `AsyncNotifier`.

### Module presentation/screens et widgets

Les écrans sont volontairement minces : ils consomment l'état via Riverpod et délèguent l'affichage à des widgets dédiés. Le `GameScreen` orchestre `AccountHeader`, deux `OfferGrid` (achat et vente), `StockPanel` et éventuellement `TimerDisplay`. Aucune logique de jeu ne doit résider dans les widgets.

## 5. Flux d'une action joueur

Lorsque le joueur tape une carte d'offre, le widget `OfferCard` invoque la méthode `selectOffer` du `GameNotifier`. Le notifier passe l'état courant et l'offre au `TransactionEngine` qui retourne un nouvel état. Le notifier passe ensuite ce nouvel état au `WinLossEvaluator` ; si la partie se termine, il émet un état final et sauvegarde le score via le `ScoreRepository`. Sinon, il appelle le `OfferGenerator` pour produire les offres du tour suivant et émet l'état mis à jour. L'UI réagit automatiquement via la souscription Riverpod et reconstruit les widgets concernés.

Ce flux unidirectionnel garantit qu'à tout moment l'état affiché est le résultat déterministe de l'application séquentielle des choix du joueur sur l'état initial du niveau, ce qui rend le débogage et les tests triviaux.

## 6. Format des fichiers de niveau

Un fichier JSON par niveau, structure prévisionnelle (à affiner en phase de tuning) :

```json
{
  "id": "level_01",
  "displayName": "Premiers pas",
  "difficulty": 1,
  "fruits": [
    { "id": "apple", "price": 2 },
    { "id": "orange", "price": 5 }
  ],
  "initialCash": 100,
  "initialStock": { "apple": 10, "orange": 10 },
  "objectiveCash": 200,
  "lossThresholdRatio": 0.5,
  "offersPerSide": 4,
  "buyTemplates": [[80, 90, 95, 110]],
  "sellTemplates": [[120, 105, 100, 85]],
  "roundingRule": "multiples_of_10"
}
```

Les pourcentages des templates sont relatifs au cours du fruit. Les valeurs concrètes (quantités achetées et prix payés) sont calculées par le générateur en respectant la règle d'arrondi. Plusieurs templates peuvent être listés et tirés au hasard à chaque tour.

## 7. Extensibilité

Trois axes d'évolution sont anticipés et l'architecture les autorise sans refonte.

**Ajout de modes de jeu** : un nouveau mode est défini par une nouvelle valeur d'enum `GameMode` et une nouvelle stratégie d'évaluation de fin de partie. Le `WinLossEvaluator` utilise un dispatch sur le mode, ce qui isole l'ajout à un seul fichier.

**Cours fluctuants** : le `GameState` contient déjà un dictionnaire de cours par fruit (et non une référence au cours initial du niveau). Pour activer la fluctuation, il suffira d'introduire un `MarketSimulator` invoqué à chaque tour avant la génération d'offres. Aucune modification du `TransactionEngine` ni de l'UI ne sera nécessaire.

**Progression et déblocage** : le `ScoreRepository` peut être étendu en `ProgressionRepository` avec des méthodes additionnelles. Le passage de SharedPreferences à Hive ou sqflite, si nécessaire, n'affecte que la couche data grâce à l'interface du domain.
