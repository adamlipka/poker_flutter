import 'dart:math';

import 'card.dart';
import 'deck.dart';
import 'hand_evaluator.dart';
import 'hand_names_pl.dart';

enum HandWinner { mathematician, chaotic, tie }

enum Player { mathematician, chaotic }

enum PokerAction {
  fold,
  check,
  call,
  raise,
}

class BettingAction {
  const BettingAction({required this.player, required this.action, required this.potAfter, this.raiseAmount});
  final Player player;
  final PokerAction action;
  final double potAfter;
  final double? raiseAmount;
}

class StageResult {
  const StageResult({
    required this.stageName,
    required this.communityRevealed,
    required this.potAtStart,
    required this.actions,
    required this.potAtEnd,
    this.winner,
    required this.pWinMath,
    required this.ev,
    required this.handNameMath,
    required this.handNameChaotic,
  });
  final String stageName;
  final int communityRevealed;
  final double potAtStart;
  final List<BettingAction> actions;
  final double potAtEnd;
  final HandWinner? winner;
  final double pWinMath;
  final double ev;
  final String handNameMath;
  final String handNameChaotic;
}

class TwoPlayerHandResult {
  const TwoPlayerHandResult({
    required this.mathematicianCards,
    required this.chaoticCards,
    required this.communityCards,
    required this.handNameMath,
    required this.handNameChaotic,
    required this.pWinMath,
    required this.ev,
    required this.winner,
    required this.capitalMath,
    required this.capitalChaotic,
    required this.stages,
  });
  final List<Card> mathematicianCards;
  final List<Card> chaoticCards;
  final List<Card> communityCards;
  final String handNameMath;
  final String handNameChaotic;
  final double pWinMath;
  final double ev;
  final HandWinner winner;
  final double capitalMath;
  final double capitalChaotic;
  final List<StageResult> stages;
}

class TwoPlayerSession {
  TwoPlayerSession({
    required this.seed,
    required this.numberOfHands,
    required this.initialCapital,
    required this.potSize,
    required this.stake,
  }) : hands = _runSession(seed, numberOfHands, initialCapital, potSize, stake);

  final int seed;
  final int numberOfHands;
  final double initialCapital;
  final double potSize;
  final double stake;
  final List<TwoPlayerHandResult> hands;

  static const _stageNames = ['Pre-flop', 'Flop', 'Turn', 'River'];
  static const _stageCommunity = [0, 3, 4, 5];

  static List<TwoPlayerHandResult> _runSession(
    int seed,
    int numberOfHands,
    double initialCapital,
    double potSize,
    double stake,
  ) {
    final smallBlind = stake >= 1 ? stake : 1.0;
    final bigBlind = smallBlind * 2;
    final results = <TwoPlayerHandResult>[];
    var capMath = initialCapital;
    var capChaos = initialCapital;
    var chaosRng = Random(seed + 1000000);

    for (var handIndex = 0; handIndex < numberOfHands; handIndex++) {
      if (capMath < bigBlind || capChaos < bigBlind) break;

      final deck = Deck();
      deck.shuffle(seed: seed + handIndex);
      final mathCards = deck.deal(2);
      final chaosCards = deck.deal(2);
      final community = deck.deal(5);

      final mathIsSB = handIndex % 2 == 0;
      if (mathIsSB) {
        capMath -= smallBlind;
        capChaos -= bigBlind;
      } else {
        capMath -= bigBlind;
        capChaos -= smallBlind;
      }
      var pot = smallBlind + bigBlind;

      final stages = <StageResult>[];
      var chaosHasCalled = false;
      var handWinner = HandWinner.tie;

      final preflopFirst = mathIsSB ? Player.mathematician : Player.chaotic;
      final postflopFirst = mathIsSB ? Player.chaotic : Player.mathematician;

      for (var stageIndex = 0; stageIndex < 4; stageIndex++) {
        final communityRevealed = _stageCommunity[stageIndex];
        final stageName = _stageNames[stageIndex];
        final initMath = stageIndex == 0 ? (mathIsSB ? smallBlind : bigBlind) : 0.0;
        final initChaos = stageIndex == 0 ? (mathIsSB ? bigBlind : smallBlind) : 0.0;
        final firstActor = stageIndex == 0 ? preflopFirst : postflopFirst;

        final result = _playBettingRound(
          name: stageName,
          communityRevealed: communityRevealed,
          initialMathContrib: initMath,
          initialChaosContrib: initChaos,
          startPot: pot,
          startCapMath: capMath,
          startCapChaos: capChaos,
          mathCards: mathCards,
          chaosCards: chaosCards,
          community: community,
          firstActor: firstActor,
          smallBlind: smallBlind,
          chaosHasCalled: chaosHasCalled,
          chaosRng: chaosRng,
        );

        capMath = result.capMath;
        capChaos = result.capChaos;
        pot = result.pot;
        chaosHasCalled = result.chaosHasCalled;
        stages.add(result.stage);

        if (result.foldWinner != null) {
          handWinner = result.foldWinner!;
          switch (handWinner) {
            case HandWinner.mathematician:
              capMath += pot;
              break;
            case HandWinner.chaotic:
              capChaos += pot;
              break;
            case HandWinner.tie:
              capMath += pot / 2;
              capChaos += pot / 2;
              break;
          }
          break;
        }

        if (stageIndex == 3) {
          final cmp = HandEvaluator.compareHands(mathCards, chaosCards, community);
          switch (cmp) {
            case 1:
              capMath += pot;
              handWinner = HandWinner.mathematician;
              break;
            case -1:
              capChaos += pot;
              handWinner = HandWinner.chaotic;
              break;
            default:
              capMath += pot / 2;
              capChaos += pot / 2;
              handWinner = HandWinner.tie;
          }
        }
      }

      final lastComm = _stageCommunity[(stages.length - 1).clamp(0, 3)];
      final lastVis = community.take(lastComm).toList();
      final evalMF = HandEvaluator.evaluateHand([...mathCards, ...lastVis]);
      final evalCF = HandEvaluator.evaluateHand([...chaosCards, ...lastVis]);

      results.add(TwoPlayerHandResult(
        mathematicianCards: mathCards,
        chaoticCards: chaosCards,
        communityCards: community,
        handNameMath: HandNamesPL.name(evalMF.handType),
        handNameChaotic: HandNamesPL.name(evalCF.handType),
        pWinMath: stages.isNotEmpty ? stages.last.pWinMath : 0.5,
        ev: stages.isNotEmpty ? stages.last.ev : 0,
        winner: handWinner,
        capitalMath: capMath,
        capitalChaotic: capChaos,
        stages: stages,
      ));
    }
    return results;
  }

  static ({StageResult stage, double capMath, double capChaos, double pot, HandWinner? foldWinner, bool chaosHasCalled}) _playBettingRound({
    required String name,
    required int communityRevealed,
    required double initialMathContrib,
    required double initialChaosContrib,
    required double startPot,
    required double startCapMath,
    required double startCapChaos,
    required List<Card> mathCards,
    required List<Card> chaosCards,
    required List<Card> community,
    required Player firstActor,
    required double smallBlind,
    required bool chaosHasCalled,
    required Random chaosRng,
  }) {
    final potAtStart = startPot;
    var pot = startPot;
    var capMath = startCapMath;
    var capChaos = startCapChaos;
    var mathContrib = initialMathContrib;
    var chaosContrib = initialChaosContrib;
    var currentBet = mathContrib > chaosContrib ? mathContrib : chaosContrib;
    final actions = <BettingAction>[];
    var raiseCount = 0;
    const maxRaises = 3;
    HandWinner? foldWinner;

    final visComm = community.take(communityRevealed).toList();
    final mathVis = [...mathCards, ...visComm];
    final chaosVis = [...chaosCards, ...visComm];
    final evalM = HandEvaluator.evaluateHand(mathVis);
    final evalC = HandEvaluator.evaluateHand(chaosVis);
    final pWinMath = _handEquity(mathVis.length, evalM);
    final pWinChaos = _handEquity(chaosVis.length, evalC);
    final refBet = smallBlind * 2;
    final ev = pWinMath * (pot + refBet) - (1 - pWinMath) * refBet;
    final hnMath = HandNamesPL.name(evalM.handType);
    final hnChaos = HandNamesPL.name(evalC.handType);

    var mathVoluntary = false;
    var chaosVoluntary = false;
    var actor = firstActor;
    var roundDone = false;
    var newChaosHasCalled = chaosHasCalled;

    while (!roundDone) {
      final actorContrib = actor == Player.mathematician ? mathContrib : chaosContrib;
      final toCall = (currentBet - actorContrib).clamp(0.0, double.infinity);
      final canCheck = toCall <= 0;
      final stack = actor == Player.mathematician ? capMath : capChaos;
      final canRaise = raiseCount < maxRaises && stack > toCall;
      final hStrength = actor == Player.mathematician ? pWinMath : pWinChaos;

      PokerAction action;
      double? raiseAmount;
      if (actor == Player.mathematician) {
        final a = _mathDecide(
          equity: hStrength,
          pot: pot,
          callAmount: toCall,
          canCheck: canCheck,
          canRaise: canRaise,
          stack: stack,
          smallBlind: smallBlind,
        );
        action = a.$1;
        raiseAmount = a.$2;
      } else {
        final a = _chaosDecide(
          handStrength: hStrength,
          pot: pot,
          callAmount: toCall,
          canCheck: canCheck,
          canRaise: canRaise,
          stack: stack,
          chaosHasCalled: chaosHasCalled,
          rng: chaosRng,
        );
        action = a.$1;
        raiseAmount = a.$2;
      }

      switch (action) {
        case PokerAction.fold:
          foldWinner = actor == Player.mathematician ? HandWinner.chaotic : HandWinner.mathematician;
          actions.add(BettingAction(player: actor, action: PokerAction.fold, potAfter: pot));
          roundDone = true;
          break;
        case PokerAction.check:
          actions.add(BettingAction(player: actor, action: PokerAction.check, potAfter: pot));
          if (actor == Player.mathematician) {
            mathVoluntary = true;
          } else {
            chaosVoluntary = true;
          }
          final other = actor == Player.mathematician ? Player.chaotic : Player.mathematician;
          BettingAction? otherPrevCheck;
          for (final a in actions.reversed) {
            if (a.player == other) {
              otherPrevCheck = a;
              break;
            }
          }
          if (otherPrevCheck != null && otherPrevCheck.action == PokerAction.check) {
            roundDone = true;
          } else {
            actor = other;
          }
          break;
        case PokerAction.call:
          final amount = toCall < stack ? toCall : stack;
          if (actor == Player.mathematician) {
            capMath -= amount;
            mathContrib += amount;
            mathVoluntary = true;
          } else {
            capChaos -= amount;
            chaosContrib += amount;
            chaosVoluntary = true;
          }
          pot += amount;
          actions.add(BettingAction(player: actor, action: PokerAction.call, potAfter: pot));
          final other = actor == Player.mathematician ? Player.chaotic : Player.mathematician;
          final otherVol = other == Player.mathematician ? mathVoluntary : chaosVoluntary;
          if (!otherVol) {
            actor = other;
          } else {
            roundDone = true;
          }
          break;
        case PokerAction.raise:
          final raiseSize = raiseAmount ?? smallBlind * 2;
          final totalAmount = (toCall + raiseSize) < stack ? (toCall + raiseSize) : stack;
          if (actor == Player.mathematician) {
            capMath -= totalAmount;
            mathContrib += totalAmount;
            currentBet = mathContrib;
            mathVoluntary = true;
          } else {
            capChaos -= totalAmount;
            chaosContrib += totalAmount;
            currentBet = chaosContrib;
            chaosVoluntary = true;
          }
          pot += totalAmount;
          raiseCount++;
          actions.add(BettingAction(player: actor, action: PokerAction.raise, potAfter: pot, raiseAmount: raiseSize));
          actor = actor == Player.mathematician ? Player.chaotic : Player.mathematician;
          break;
      }
    }

    BettingAction? lastChaos;
    for (final a in actions.reversed) {
      if (a.player == Player.chaotic) {
        lastChaos = a;
        break;
      }
    }
    if (lastChaos != null) {
      switch (lastChaos.action) {
        case PokerAction.call:
        case PokerAction.raise:
        case PokerAction.check:
          newChaosHasCalled = true;
          break;
        case PokerAction.fold:
          newChaosHasCalled = false;
          break;
      }
    }

    final stage = StageResult(
      stageName: name,
      communityRevealed: communityRevealed,
      potAtStart: potAtStart,
      actions: actions,
      potAtEnd: pot,
      winner: foldWinner,
      pWinMath: pWinMath,
      ev: ev,
      handNameMath: hnMath,
      handNameChaotic: hnChaos,
    );
    return (stage: stage, capMath: capMath, capChaos: capChaos, pot: pot, foldWinner: foldWinner, chaosHasCalled: newChaosHasCalled);
  }

  static (PokerAction, double?) _mathDecide({
    required double equity,
    required double pot,
    required double callAmount,
    required bool canCheck,
    required bool canRaise,
    required double stack,
    required double smallBlind,
  }) {
    final minRaise = smallBlind * 2 >= 1 ? smallBlind * 2 : 1.0;
    if (canCheck) {
      if (canRaise && equity > 0.60) {
        var rs = pot * 0.65;
        if (rs < minRaise) rs = minRaise;
        if (rs > stack) rs = stack;
        if (rs >= minRaise) return (PokerAction.raise, rs);
      }
      return (PokerAction.check, null);
    }
    final potOdds = callAmount / (pot + callAmount);
    if (equity >= potOdds) {
      if (canRaise && equity > potOdds * 1.30) {
        var rs = pot * 0.65 + callAmount;
        if (rs < minRaise) rs = minRaise;
        if (rs > stack) rs = stack;
        if (rs > callAmount) return (PokerAction.raise, rs - callAmount);
      }
      return (PokerAction.call, null);
    }
    return (PokerAction.fold, null);
  }

  static (PokerAction, double?) _chaosDecide({
    required double handStrength,
    required double pot,
    required double callAmount,
    required bool canCheck,
    required bool canRaise,
    required double stack,
    required bool chaosHasCalled,
    required Random rng,
  }) {
    final noise = rng.nextDouble() * 0.25 - 0.10;
    final pCont = (0.70 + noise).clamp(0.50, 1.0);
    if (canCheck) {
      if (canRaise && rng.nextDouble() > 0.65) {
        final factor = 0.3 + rng.nextDouble() * 1.2;
        var rs = pot * factor;
        if (rs < 1) rs = 1;
        if (rs > stack) rs = stack;
        if (rs > 0) return (PokerAction.raise, rs);
      }
      return (PokerAction.check, null);
    }
    if (rng.nextDouble() > pCont) return (PokerAction.fold, null);
    if (canRaise && rng.nextDouble() > 0.75) {
      final factor = 0.3 + rng.nextDouble() * 0.7;
      var rs = pot * factor;
      if (rs < 1) rs = 1;
      if (rs > stack - callAmount) rs = stack - callAmount;
      if (rs > 0) return (PokerAction.raise, rs);
    }
    return (PokerAction.call, null);
  }

  static double _handEquity(int cardsCount, HandEvaluation eval) {
    if (cardsCount <= 2) {
      return (eval.value / 350.0).clamp(0.0, 1.0);
    }
    final handType = eval.handType;
    if (handType == null) return 0.30;
    switch (handType) {
      case HandType.highCard:
        return 0.25 + 0.25 * (eval.value / 999).clamp(0.0, 1.0);
      case HandType.onePair:
        return 0.58 + 0.14 * ((eval.value - 1000) / 1601).clamp(0.0, 1.0);
      case HandType.twoPair:
        return 0.74 + 0.07 * ((eval.value - 2002) / 1540).clamp(0.0, 1.0);
      case HandType.threeOfAKind:
        return 0.82 + 0.05 * ((eval.value - 3002) / 1540).clamp(0.0, 1.0);
      case HandType.straight:
        return 0.87 + 0.02 * ((eval.value - 4005) / 9).clamp(0.0, 1.0);
      case HandType.flush:
        return 0.89 + 0.04 * ((eval.value - 5000) / 115000).clamp(0.0, 1.0);
      case HandType.fullHouse:
        return 0.93 + 0.03 * ((eval.value - 6002) / 1411).clamp(0.0, 1.0);
      case HandType.fourOfAKind:
        return 0.96 + 0.02 * ((eval.value - 7002) / 1411).clamp(0.0, 1.0);
      case HandType.straightFlush:
        return 0.98 + 0.01 * ((eval.value - 8005) / 9).clamp(0.0, 1.0);
      case HandType.royalFlush:
        return 0.99;
      default:
        return (eval.value / 350.0).clamp(0.0, 1.0);
    }
  }

  double get finalCapitalMath => hands.isNotEmpty ? hands.last.capitalMath : initialCapital;
  double get finalCapitalChaotic => hands.isNotEmpty ? hands.last.capitalChaotic : initialCapital;
}
