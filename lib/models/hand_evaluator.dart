import 'dart:math';

import 'card.dart';

/// Recursive combinations of list elements.
List<List<T>> combinations<T>(List<T> list, int k) {
  if (k == 0) return [[]];
  if (k > list.length) return [];
  if (k == list.length) return [List.from(list)];
  final result = <List<T>>[];
  for (var i = 0; i <= list.length - k; i++) {
    final head = list[i];
    final rest = list.sublist(i + 1);
    for (final combo in combinations(rest, k - 1)) {
      result.add([head, ...combo]);
    }
  }
  return result;
}

enum HandType {
  royalFlush,
  straightFlush,
  fourOfAKind,
  fullHouse,
  flush,
  straight,
  threeOfAKind,
  twoPair,
  onePair,
  highCard,
  pair,
  suitedCards,
  offSuitCards,
}

class HandEvaluation {
  const HandEvaluation({this.handType, required this.value});
  final HandType? handType;
  final int value;
}

class HandEvaluator {
  static HandEvaluation evaluateHand(List<Card> cards) {
    if (cards.length < 5) {
      if (cards.length == 2) return _evaluatePreFlop(cards);
      return const HandEvaluation(handType: null, value: 0);
    }
    var bestType = HandType.highCard;
    var bestValue = 0;
    for (final combo in combinations(cards, 5)) {
      final (t, v) = _evaluateFiveCards(combo);
      if (v > bestValue) {
        bestValue = v;
        bestType = t;
      }
    }
    return HandEvaluation(handType: bestType, value: bestValue);
  }

  static bool _isStraight(List<int> ranks) {
    final r = ranks.toSet().toList()..sort();
    if (r.length < 5) return false;
    for (var i = 0; i <= r.length - 5; i++) {
      if (r[i + 4] - r[i] == 4) return true;
    }
    if (r.contains(14)) {
      final low = r.map((x) => x == 14 ? 1 : x).toList()..sort();
      for (var i = 0; i <= low.length - 5; i++) {
        if (low[i + 4] - low[i] == 4) return true;
      }
    }
    return false;
  }

  static (HandType, int) _evaluateFiveCards(List<Card> cards) {
    final ranks = cards.map((c) => c.rank.value).toList()..sort();
    final rankCounts = <int, int>{};
    for (final r in ranks) {
      rankCounts[r] = (rankCounts[r] ?? 0) + 1;
    }
    final counts = rankCounts.values.toList()..sort((a, b) => b.compareTo(a));
    final suits = cards.map((c) => c.suit).toSet();
    final isFlush = suits.length == 1;
    final isStraight = _isStraight(ranks);

    if (isFlush && isStraight && ranks.reduce(min) == 10) {
      return (HandType.royalFlush, 9000 + ranks.reduce(max));
    }
    if (isFlush && isStraight) {
      return (HandType.straightFlush, 8000 + ranks.reduce(max));
    }
    if (counts[0] == 4) {
      final fourRank = rankCounts.entries.firstWhere((e) => e.value == 4).key;
      final kicker = rankCounts.entries.firstWhere((e) => e.value == 1).key;
      return (HandType.fourOfAKind, 7000 + fourRank * 100 + kicker);
    }
    if (counts[0] == 3 && counts[1] == 2) {
      final threeRank = rankCounts.entries.firstWhere((e) => e.value == 3).key;
      final twoRank = rankCounts.entries.firstWhere((e) => e.value == 2).key;
      return (HandType.fullHouse, 6000 + threeRank * 100 + twoRank);
    }
    if (isFlush) {
      final sorted = ranks.reversed.take(5).toList();
      var score = 0;
      for (var i = 0; i < sorted.length; i++) {
        score += sorted[i] * pow(10, i).toInt();
      }
      return (HandType.flush, 5000 + score);
    }
    if (isStraight) {
      return (HandType.straight, 4000 + ranks.reduce(max));
    }
    if (counts[0] == 3) {
      final threeRank = rankCounts.entries.firstWhere((e) => e.value == 3).key;
      final kickers = rankCounts.entries.where((e) => e.value == 1).map((e) => e.key).toList()..sort((a, b) => b.compareTo(a));
      final k0 = kickers.isNotEmpty ? kickers[0] : 0;
      final k1 = kickers.length > 1 ? kickers[1] : 0;
      return (HandType.threeOfAKind, 3000 + threeRank * 100 + k0 * 10 + k1);
    }
    if (counts[0] == 2 && counts[1] == 2) {
      final pairs = rankCounts.entries.where((e) => e.value == 2).map((e) => e.key).toList()..sort((a, b) => b.compareTo(a));
      final kicker = rankCounts.entries.firstWhere((e) => e.value == 1).key;
      return (HandType.twoPair, 2000 + pairs[0] * 100 + pairs[1] * 10 + kicker);
    }
    if (counts[0] == 2) {
      final pairRank = rankCounts.entries.firstWhere((e) => e.value == 2).key;
      final kickers = rankCounts.entries.where((e) => e.value == 1).map((e) => e.key).toList()..sort((a, b) => b.compareTo(a));
      final k0 = kickers.isNotEmpty ? kickers[0] : 0;
      final k1 = kickers.length > 1 ? kickers[1] : 0;
      final k2 = kickers.length > 2 ? kickers[2] : 0;
      return (HandType.onePair, 1000 + pairRank * 100 + k0 * 10 + k1 * 5 + k2);
    }
    final sorted = ranks.reversed.take(5).toList();
    var score = 0;
    for (var i = 0; i < sorted.length; i++) {
      score += sorted[i] * pow(10, i).toInt();
    }
    final highCardValue = (score / 112).round().clamp(0, 999);
    return (HandType.highCard, highCardValue);
  }

  static int compareHands(List<Card> playerA, List<Card> playerB, List<Card> community) {
    final evalA = evaluateHand([...playerA, ...community]);
    final evalB = evaluateHand([...playerB, ...community]);
    if (evalA.value > evalB.value) return 1;
    if (evalA.value < evalB.value) return -1;
    return 0;
  }

  static HandEvaluation _evaluatePreFlop(List<Card> cards) {
    if (cards.length != 2) return const HandEvaluation(handType: null, value: 0);
    final r0 = cards[0].rank.value;
    final r1 = cards[1].rank.value;
    final suited = cards[0].suit == cards[1].suit;
    if (r0 == r1) {
      return HandEvaluation(handType: HandType.pair, value: r0 * 100);
    }
    final high = r0 > r1 ? r0 : r1;
    final low = r0 < r1 ? r0 : r1;
    final gap = (r0 - r1).abs();
    final gapBonus = gap <= 4 ? (5 - gap) * 2 : 0;
    final suitedBonus = suited ? 10 : 0;
    final handValue = high * 10 + low + suitedBonus + gapBonus;
    return HandEvaluation(
      handType: suited ? HandType.suitedCards : HandType.offSuitCards,
      value: handValue,
    );
  }
}
