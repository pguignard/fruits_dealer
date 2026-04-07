import 'package:flutter_test/flutter_test.dart';
import 'package:fruits_trader/domain/entities/offer.dart';

void main() {
  group('Offer — pattern matching exhaustif', () {
    const buyOffer = BuyOffer(fruitId: 'apple', quantity: 10, totalPrice: 18);
    const sellOffer = SellOffer(fruitId: 'orange', quantity: 5, totalPrice: 28);

    test('switch exhaustif reconnait BuyOffer', () {
      final Offer offer = buyOffer;
      final String label = switch (offer) {
        BuyOffer() => 'achat',
        SellOffer() => 'vente',
      };
      expect(label, equals('achat'));
    });

    test('switch exhaustif reconnait SellOffer', () {
      final Offer offer = sellOffer;
      final String label = switch (offer) {
        BuyOffer() => 'achat',
        SellOffer() => 'vente',
      };
      expect(label, equals('vente'));
    });

    test('acces aux champs dans le pattern matching', () {
      final Offer offer = buyOffer;
      final int price = switch (offer) {
        BuyOffer(:final totalPrice) => totalPrice,
        SellOffer(:final totalPrice) => totalPrice,
      };
      expect(price, equals(18));
    });

    test('if-case fonctionne sur BuyOffer', () {
      final Offer offer = buyOffer;
      var isBuy = false;
      if (offer case BuyOffer()) {
        isBuy = true;
      }
      expect(isBuy, isTrue);
    });

    test('if-case fonctionne sur SellOffer', () {
      final Offer offer = sellOffer;
      var isSell = false;
      if (offer case SellOffer()) {
        isSell = true;
      }
      expect(isSell, isTrue);
    });
  });

  group('BuyOffer — egalite de valeur', () {
    const a = BuyOffer(fruitId: 'apple', quantity: 10, totalPrice: 18);
    const b = BuyOffer(fruitId: 'apple', quantity: 10, totalPrice: 18);
    const c = BuyOffer(fruitId: 'apple', quantity: 10, totalPrice: 20);

    test('deux instances identiques sont egales', () {
      expect(a, equals(b));
    });

    test('hashCode identique pour instances egales', () {
      expect(a.hashCode, equals(b.hashCode));
    });

    test('difference sur totalPrice rompt l\'egalite', () {
      expect(a, isNot(equals(c)));
    });

    test('BuyOffer et SellOffer avec memes champs ne sont pas egales', () {
      const sell = SellOffer(fruitId: 'apple', quantity: 10, totalPrice: 18);
      expect(a, isNot(equals(sell)));
    });
  });

  group('SellOffer — egalite de valeur', () {
    const a = SellOffer(fruitId: 'orange', quantity: 5, totalPrice: 28);
    const b = SellOffer(fruitId: 'orange', quantity: 5, totalPrice: 28);
    const c = SellOffer(fruitId: 'banana', quantity: 5, totalPrice: 28);

    test('deux instances identiques sont egales', () {
      expect(a, equals(b));
    });

    test('hashCode identique pour instances egales', () {
      expect(a.hashCode, equals(b.hashCode));
    });

    test('difference sur fruitId rompt l\'egalite', () {
      expect(a, isNot(equals(c)));
    });
  });

  group('Offer — champs communs accessibles depuis le type parent', () {
    test('fruitId accessible depuis Offer', () {
      final Offer offer = BuyOffer(fruitId: 'cherry', quantity: 3, totalPrice: 6);
      expect(offer.fruitId, equals('cherry'));
    });

    test('quantity accessible depuis Offer', () {
      final Offer offer = SellOffer(fruitId: 'grape', quantity: 7, totalPrice: 21);
      expect(offer.quantity, equals(7));
    });

    test('totalPrice accessible depuis Offer', () {
      final Offer offer = BuyOffer(fruitId: 'apricot', quantity: 4, totalPrice: 12);
      expect(offer.totalPrice, equals(12));
    });
  });
}
