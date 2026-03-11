/// Card model: rank + suit. Port from Swift poker Card.
enum Suit {
  hearts('H'),
  diamonds('D'),
  clubs('C'),
  spades('S');

  const Suit(this.code);
  final String code;

  String get symbol {
    switch (this) {
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
      case Suit.spades:
        return '♠';
    }
  }

  bool get isRed => this == Suit.hearts || this == Suit.diamonds;

  static List<Suit> get all => [Suit.hearts, Suit.diamonds, Suit.clubs, Suit.spades];
}

enum Rank {
  r2('2'),
  r3('3'),
  r4('4'),
  r5('5'),
  r6('6'),
  r7('7'),
  r8('8'),
  r9('9'),
  r10('10'),
  jack('J'),
  queen('Q'),
  king('K'),
  ace('A');

  const Rank(this.display);
  final String display;

  int get value {
    switch (this) {
      case Rank.r2:
        return 2;
      case Rank.r3:
        return 3;
      case Rank.r4:
        return 4;
      case Rank.r5:
        return 5;
      case Rank.r6:
        return 6;
      case Rank.r7:
        return 7;
      case Rank.r8:
        return 8;
      case Rank.r9:
        return 9;
      case Rank.r10:
        return 10;
      case Rank.jack:
        return 11;
      case Rank.queen:
        return 12;
      case Rank.king:
        return 13;
      case Rank.ace:
        return 14;
    }
  }

  static List<Rank> get all =>
      [Rank.r2, Rank.r3, Rank.r4, Rank.r5, Rank.r6, Rank.r7, Rank.r8, Rank.r9, Rank.r10, Rank.jack, Rank.queen, Rank.king, Rank.ace];
}

class Card {
  const Card({required this.rank, required this.suit});
  final Rank rank;
  final Suit suit;

  String get displayShort => '${rank.display}${suit.symbol}';

  @override
  bool operator ==(Object other) => identical(this, other) || other is Card && rank == other.rank && suit == other.suit;
  @override
  int get hashCode => Object.hash(rank, suit);
}
