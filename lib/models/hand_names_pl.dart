import 'hand_evaluator.dart';

/// Polish hand names per spec.
class HandNamesPL {
  static String name(HandType? handType) {
    if (handType == null) return '—';
    switch (handType) {
      case HandType.royalFlush:
        return 'poker królewski';
      case HandType.straightFlush:
        return 'poker';
      case HandType.fourOfAKind:
        return 'kareta';
      case HandType.fullHouse:
        return 'full';
      case HandType.flush:
        return 'kolor';
      case HandType.straight:
        return 'strit';
      case HandType.threeOfAKind:
        return 'trójka';
      case HandType.twoPair:
        return 'dwie pary';
      case HandType.onePair:
        return 'para';
      case HandType.highCard:
        return 'wysoka karta';
      case HandType.pair:
        return 'para (pre-flop)';
      case HandType.suitedCards:
        return 'karty w kolorze';
      case HandType.offSuitCards:
        return 'karty nie w kolorze';
    }
  }
}
