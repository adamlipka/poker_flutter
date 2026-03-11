import 'dart:math';

import 'card.dart';

/// Full 52-card deck; shuffle with optional seed for repeatability.
class Deck {
  Deck() {
    _cards = [];
    for (final suit in Suit.all) {
      for (final rank in Rank.all) {
        _cards.add(Card(rank: rank, suit: suit));
      }
    }
  }

  late List<Card> _cards;

  void shuffle({int? seed}) {
    if (seed != null) {
      _cards.shuffle(Random(seed));
    } else {
      _cards.shuffle();
    }
  }

  List<Card> deal(int count) {
    final dealt = _cards.take(count).toList();
    _cards.removeRange(0, count.clamp(0, _cards.length));
    return dealt;
  }
}
