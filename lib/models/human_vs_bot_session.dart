import 'dart:math';

import 'card.dart';
import 'deck.dart';
import 'game_config.dart';
import 'hand_evaluator.dart';
import 'hand_names_pl.dart';
import 'two_player_session.dart' show PokerAction;

enum HumanBotActor { human, bot }

enum HumanBotWinner { human, bot, tie }

class HumanBettingAction {
  const HumanBettingAction({
    required this.actor,
    required this.action,
    required this.potAfter,
    this.raiseAmount,
  });

  final HumanBotActor actor;
  final PokerAction action;
  final double potAfter;
  final double? raiseAmount;
}

class HumanStageResult {
  const HumanStageResult({
    required this.stageName,
    required this.communityRevealed,
    required this.potAtStart,
    required this.actions,
    required this.potAtEnd,
    this.winner,
    required this.pWinHuman,
    required this.ev,
    required this.handNameHuman,
    required this.handNameBot,
  });

  final String stageName;
  final int communityRevealed;
  final double potAtStart;
  final List<HumanBettingAction> actions;
  final double potAtEnd;
  final HumanBotWinner? winner;
  final double pWinHuman;
  final double ev;
  final String handNameHuman;
  final String handNameBot;
}

class HumanVsBotHandResult {
  const HumanVsBotHandResult({
    required this.humanCards,
    required this.botCards,
    required this.communityCards,
    required this.handNameHuman,
    required this.handNameBot,
    required this.winner,
    required this.capitalHuman,
    required this.capitalBot,
    required this.stages,
    required this.showdownReached,
  });

  final List<Card> humanCards;
  final List<Card> botCards;
  final List<Card> communityCards;
  final String handNameHuman;
  final String handNameBot;
  final HumanBotWinner winner;
  final double capitalHuman;
  final double capitalBot;
  final List<HumanStageResult> stages;
  final bool showdownReached;
}

class HumanVsBotSession {
  HumanVsBotSession({
    required this.seed,
    required this.initialCapital,
    required this.potSize,
    required this.stake,
    required this.botType,
  }) : smallBlind = stake >= 1 ? stake : 1.0,
       bigBlind = (stake >= 1 ? stake : 1.0) * 2,
       humanCapital = initialCapital,
       botCapital = initialCapital,
       _chaosRng = Random(seed + 1000000) {
    _startNewHand();
  }

  final int seed;
  final double initialCapital;
  final double potSize;
  final double stake;
  final BotType botType;
  final double smallBlind;
  final double bigBlind;
  final Random _chaosRng;

  static const List<String> _stageNames = ['Pre-flop', 'Flop', 'Turn', 'River'];
  static const List<int> _stageCommunity = [0, 3, 4, 5];
  static const int _maxRaisesPerRound = 3;

  double humanCapital;
  double botCapital;

  bool isMatchOver = false;
  bool _hasCurrentHand = false;
  bool _handOver = false;
  bool _showdownReached = false;
  bool _revealBotCards = false;

  int _handIndex = 0;
  bool _humanIsSB = true;
  HumanBotWinner? _handWinner;

  List<Card> _humanCards = const [];
  List<Card> _botCards = const [];
  List<Card> _communityCards = const [];

  int _stageIndex = 0;
  double _pot = 0;
  double _stagePotAtStart = 0;
  double _humanRoundContrib = 0;
  double _botRoundContrib = 0;
  double _currentBet = 0;
  int _raiseCount = 0;
  HumanBotActor _actorToAct = HumanBotActor.human;

  double _stagePWinHuman = 0.5;
  double _stageEv = 0;
  String _stageHandNameHuman = '—';
  String _stageHandNameBot = '—';
  final List<HumanBettingAction> _currentStageActions = [];
  final List<HumanStageResult> _stages = [];

  final List<HumanVsBotHandResult> _history = [];

  bool get hasCurrentHand => _hasCurrentHand;
  bool get isHandOver => _handOver;
  bool get revealBotCards => _revealBotCards;
  int get handNumber => _handIndex + 1;
  int get currentStageIndex => _stageIndex;
  String get currentStageName => _stageNames[_stageIndex];
  double get pot => _pot;
  HumanBotActor get actorToAct => _actorToAct;
  String get humanBlindLabel => _humanIsSB ? 'SB' : 'BB';
  String get botBlindLabel => _humanIsSB ? 'BB' : 'SB';
  List<Card> get humanCards => _humanCards;
  List<Card> get botCards => _botCards;
  List<Card> get visibleCommunityCards =>
      _communityCards.take(_stageCommunity[_stageIndex]).toList();
  List<HumanStageResult> get stages => List.unmodifiable(_stages);
  List<HumanVsBotHandResult> get history => List.unmodifiable(_history);

  bool get isHumanTurn =>
      _hasCurrentHand && !_handOver && _actorToAct == HumanBotActor.human;

  bool get canHumanCheck {
    if (!isHumanTurn) return false;
    return _toCallFor(HumanBotActor.human) <= 0;
  }

  bool get canHumanCall {
    if (!isHumanTurn) return false;
    return _toCallFor(HumanBotActor.human) > 0;
  }

  bool get canHumanRaise {
    if (!isHumanTurn) return false;
    final toCall = _toCallFor(HumanBotActor.human);
    return _raiseCount < _maxRaisesPerRound && humanCapital > toCall;
  }

  bool get canHumanFold {
    if (!isHumanTurn) return false;
    return _toCallFor(HumanBotActor.human) > 0;
  }

  String get humanCheckOrCallLabel => canHumanCheck ? 'Check' : 'Call';
  double get humanCallCost {
    if (!isHumanTurn) return 0;
    final toCall = _toCallFor(HumanBotActor.human);
    return toCall < humanCapital ? toCall : humanCapital;
  }

  double get humanRaiseIncrement {
    if (!canHumanRaise) return 0;
    return _suggestedHumanRaiseIncrement();
  }

  double get humanRaiseTotalCost {
    if (!canHumanRaise) return 0;
    return humanCallCost + humanRaiseIncrement;
  }

  String get handResultLabel {
    if (_handWinner == null) return 'Rozdanie w toku';
    switch (_handWinner!) {
      case HumanBotWinner.human:
        return 'Wygrywasz rozdanie';
      case HumanBotWinner.bot:
        return 'Bot wygrywa rozdanie';
      case HumanBotWinner.tie:
        return 'Remis';
    }
  }

  String get matchResultLabel {
    if (!isMatchOver) return 'Mecz w toku';
    if (humanCapital > botCapital) return 'Koniec meczu: wygrywasz';
    if (humanCapital < botCapital) return 'Koniec meczu: wygrywa bot';
    return 'Koniec meczu: remis';
  }

  HumanStageResult get stageForUi {
    if (_handOver && _stages.isNotEmpty) {
      return _stages.last;
    }
    return HumanStageResult(
      stageName: _stageNames[_stageIndex],
      communityRevealed: _stageCommunity[_stageIndex],
      potAtStart: _stagePotAtStart,
      actions: List.unmodifiable(_currentStageActions),
      potAtEnd: _pot,
      winner: null,
      pWinHuman: _stagePWinHuman,
      ev: _stageEv,
      handNameHuman: _stageHandNameHuman,
      handNameBot: _revealBotCards ? _stageHandNameBot : 'karty ukryte',
    );
  }

  void humanFold() {
    if (!canHumanFold) return;
    _applyAction(HumanBotActor.human, PokerAction.fold, null);
    _processBotTurns();
  }

  void humanCheckOrCall() {
    if (!isHumanTurn) return;
    if (canHumanCheck) {
      _applyAction(HumanBotActor.human, PokerAction.check, null);
    } else if (canHumanCall) {
      _applyAction(HumanBotActor.human, PokerAction.call, null);
    }
    _processBotTurns();
  }

  void humanRaise() {
    if (!canHumanRaise) return;
    final raiseSize = _suggestedHumanRaiseIncrement();
    if (raiseSize <= 0) {
      humanCheckOrCall();
      return;
    }
    _applyAction(HumanBotActor.human, PokerAction.raise, raiseSize);
    _processBotTurns();
  }

  void startNextHand() {
    if (!_handOver || isMatchOver) return;
    _startNewHand();
  }

  void _startNewHand() {
    if (humanCapital < bigBlind || botCapital < bigBlind) {
      isMatchOver = true;
      _hasCurrentHand = false;
      return;
    }

    _hasCurrentHand = true;
    _handOver = false;
    _showdownReached = false;
    _revealBotCards = false;
    _handWinner = null;
    _stages.clear();
    _currentStageActions.clear();

    final deck = Deck();
    deck.shuffle(seed: seed + _handIndex);
    _humanCards = deck.deal(2);
    _botCards = deck.deal(2);
    _communityCards = deck.deal(5);

    _humanIsSB = _handIndex % 2 == 0;
    if (_humanIsSB) {
      humanCapital -= smallBlind;
      botCapital -= bigBlind;
      _humanRoundContrib = smallBlind;
      _botRoundContrib = bigBlind;
    } else {
      humanCapital -= bigBlind;
      botCapital -= smallBlind;
      _humanRoundContrib = bigBlind;
      _botRoundContrib = smallBlind;
    }
    _pot = smallBlind + bigBlind;
    _stageIndex = 0;
    _currentBet = _humanRoundContrib > _botRoundContrib
        ? _humanRoundContrib
        : _botRoundContrib;
    _raiseCount = 0;
    _actorToAct = _humanIsSB ? HumanBotActor.human : HumanBotActor.bot;
    _stagePotAtStart = _pot;
    _recomputeStageStats();
    _processBotTurns();
  }

  void _processBotTurns() {
    while (_hasCurrentHand && !_handOver && _actorToAct == HumanBotActor.bot) {
      final toCall = _toCallFor(HumanBotActor.bot);
      final canCheck = toCall <= 0;
      final stack = botCapital;
      final canRaise = _raiseCount < _maxRaisesPerRound && stack > toCall;
      final visibleCommunity = _communityCards
          .take(_stageCommunity[_stageIndex])
          .toList();
      final evalBot = HandEvaluator.evaluateHand([
        ..._botCards,
        ...visibleCommunity,
      ]);
      final pWinBot = _handEquity(
        _botCards.length + visibleCommunity.length,
        evalBot,
      );

      final (action, raiseAmount) = switch (botType) {
        BotType.mathematician => _mathDecide(
          equity: pWinBot,
          pot: _pot,
          callAmount: toCall,
          canCheck: canCheck,
          canRaise: canRaise,
          stack: stack,
          smallBlind: smallBlind,
        ),
        BotType.chaotic => _chaosDecide(
          pot: _pot,
          callAmount: toCall,
          canCheck: canCheck,
          canRaise: canRaise,
          stack: stack,
          rng: _chaosRng,
        ),
      };

      _applyAction(HumanBotActor.bot, action, raiseAmount);
    }
  }

  void _applyAction(
    HumanBotActor actor,
    PokerAction action,
    double? raiseAmount,
  ) {
    if (_handOver) return;

    final actorContrib = actor == HumanBotActor.human
        ? _humanRoundContrib
        : _botRoundContrib;
    final toCall = (_currentBet - actorContrib).clamp(0.0, double.infinity);
    final canCheck = toCall <= 0;

    switch (action) {
      case PokerAction.fold:
        final winner = actor == HumanBotActor.human
            ? HumanBotWinner.bot
            : HumanBotWinner.human;
        _currentStageActions.add(
          HumanBettingAction(
            actor: actor,
            action: PokerAction.fold,
            potAfter: _pot,
          ),
        );
        _finishCurrentStage(winner: winner);
        _awardPot(winner);
        _finishHand(winner: winner, showdownReached: false);
        return;
      case PokerAction.check:
        if (!canCheck) return;
        _currentStageActions.add(
          HumanBettingAction(
            actor: actor,
            action: PokerAction.check,
            potAfter: _pot,
          ),
        );
        final shouldCloseRound =
            _currentStageActions.length >= 2 &&
            _currentStageActions[_currentStageActions.length - 2].action ==
                PokerAction.check &&
            _currentStageActions[_currentStageActions.length - 2].actor !=
                actor;
        if (shouldCloseRound) {
          _finishBettingRoundWithoutFold();
        } else {
          _actorToAct = _otherActor(actor);
        }
        return;
      case PokerAction.call:
        if (canCheck) return;
        final stack = actor == HumanBotActor.human ? humanCapital : botCapital;
        final amount = toCall < stack ? toCall : stack;
        if (actor == HumanBotActor.human) {
          humanCapital -= amount;
          _humanRoundContrib += amount;
        } else {
          botCapital -= amount;
          _botRoundContrib += amount;
        }
        _pot += amount;
        _currentStageActions.add(
          HumanBettingAction(
            actor: actor,
            action: PokerAction.call,
            potAfter: _pot,
          ),
        );
        _finishBettingRoundWithoutFold();
        return;
      case PokerAction.raise:
        final stack = actor == HumanBotActor.human ? humanCapital : botCapital;
        if (!(_raiseCount < _maxRaisesPerRound && stack > toCall)) return;
        var raiseSize = raiseAmount ?? bigBlind;
        if (raiseSize < 1) raiseSize = 1;
        final totalAmount = (toCall + raiseSize) < stack
            ? (toCall + raiseSize)
            : stack;
        if (totalAmount <= toCall) return;
        final appliedRaise = totalAmount - toCall;
        if (actor == HumanBotActor.human) {
          humanCapital -= totalAmount;
          _humanRoundContrib += totalAmount;
          _currentBet = _humanRoundContrib;
        } else {
          botCapital -= totalAmount;
          _botRoundContrib += totalAmount;
          _currentBet = _botRoundContrib;
        }
        _pot += totalAmount;
        _raiseCount++;
        _currentStageActions.add(
          HumanBettingAction(
            actor: actor,
            action: PokerAction.raise,
            potAfter: _pot,
            raiseAmount: appliedRaise,
          ),
        );
        _actorToAct = _otherActor(actor);
        return;
    }
  }

  void _finishBettingRoundWithoutFold() {
    if (_stageIndex == _stageNames.length - 1) {
      final cmp = HandEvaluator.compareHands(
        _humanCards,
        _botCards,
        _communityCards,
      );
      final winner = switch (cmp) {
        1 => HumanBotWinner.human,
        -1 => HumanBotWinner.bot,
        _ => HumanBotWinner.tie,
      };
      _finishCurrentStage(winner: winner);
      _awardPot(winner);
      _finishHand(winner: winner, showdownReached: true);
      return;
    }

    _finishCurrentStage();
    _startNextStage();
  }

  void _startNextStage() {
    _stageIndex++;
    _humanRoundContrib = 0;
    _botRoundContrib = 0;
    _currentBet = 0;
    _raiseCount = 0;
    _currentStageActions.clear();
    _actorToAct = _humanIsSB ? HumanBotActor.bot : HumanBotActor.human;
    _stagePotAtStart = _pot;
    _recomputeStageStats();
  }

  void _finishCurrentStage({HumanBotWinner? winner}) {
    _stages.add(
      HumanStageResult(
        stageName: _stageNames[_stageIndex],
        communityRevealed: _stageCommunity[_stageIndex],
        potAtStart: _stagePotAtStart,
        actions: List.unmodifiable(_currentStageActions),
        potAtEnd: _pot,
        winner: winner,
        pWinHuman: _stagePWinHuman,
        ev: _stageEv,
        handNameHuman: _stageHandNameHuman,
        handNameBot: _stageHandNameBot,
      ),
    );
  }

  void _finishHand({
    required HumanBotWinner winner,
    required bool showdownReached,
  }) {
    _handWinner = winner;
    _handOver = true;
    _showdownReached = showdownReached;
    _revealBotCards = showdownReached;

    final evalHuman = HandEvaluator.evaluateHand([
      ..._humanCards,
      ..._communityCards,
    ]);
    final evalBot = HandEvaluator.evaluateHand([
      ..._botCards,
      ..._communityCards,
    ]);

    _history.add(
      HumanVsBotHandResult(
        humanCards: List.unmodifiable(_humanCards),
        botCards: List.unmodifiable(_botCards),
        communityCards: List.unmodifiable(_communityCards),
        handNameHuman: HandNamesPL.name(evalHuman.handType),
        handNameBot: HandNamesPL.name(evalBot.handType),
        winner: winner,
        capitalHuman: humanCapital,
        capitalBot: botCapital,
        stages: List.unmodifiable(_stages),
        showdownReached: _showdownReached,
      ),
    );

    _handIndex++;
    if (humanCapital < bigBlind || botCapital < bigBlind) {
      isMatchOver = true;
    }
  }

  void _recomputeStageStats() {
    final visibleCommunity = _communityCards
        .take(_stageCommunity[_stageIndex])
        .toList();
    final evalHuman = HandEvaluator.evaluateHand([
      ..._humanCards,
      ...visibleCommunity,
    ]);
    final evalBot = HandEvaluator.evaluateHand([
      ..._botCards,
      ...visibleCommunity,
    ]);
    _stagePWinHuman = _handEquity(
      _humanCards.length + visibleCommunity.length,
      evalHuman,
    );
    final refBet = bigBlind;
    _stageEv =
        _stagePWinHuman * (_pot + refBet) - (1 - _stagePWinHuman) * refBet;
    _stageHandNameHuman = HandNamesPL.name(evalHuman.handType);
    _stageHandNameBot = HandNamesPL.name(evalBot.handType);
  }

  double _toCallFor(HumanBotActor actor) {
    final contrib = actor == HumanBotActor.human
        ? _humanRoundContrib
        : _botRoundContrib;
    return (_currentBet - contrib).clamp(0.0, double.infinity);
  }

  double _suggestedHumanRaiseIncrement() {
    final toCall = _toCallFor(HumanBotActor.human);
    final maxRaiseIncrement = humanCapital - toCall;
    if (maxRaiseIncrement <= 0) return 0;
    final minRaise = bigBlind >= 1 ? bigBlind : 1.0;
    var raiseSize = _pot * 0.65;
    if (raiseSize < minRaise) raiseSize = minRaise;
    if (raiseSize > maxRaiseIncrement) raiseSize = maxRaiseIncrement;
    return raiseSize > 0 ? raiseSize : 0;
  }

  HumanBotActor _otherActor(HumanBotActor actor) {
    return actor == HumanBotActor.human
        ? HumanBotActor.bot
        : HumanBotActor.human;
  }

  void _awardPot(HumanBotWinner winner) {
    switch (winner) {
      case HumanBotWinner.human:
        humanCapital += _pot;
      case HumanBotWinner.bot:
        botCapital += _pot;
      case HumanBotWinner.tie:
        humanCapital += _pot / 2;
        botCapital += _pot / 2;
    }
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
        var raiseSize = pot * 0.65;
        if (raiseSize < minRaise) raiseSize = minRaise;
        if (raiseSize > stack) raiseSize = stack;
        if (raiseSize >= minRaise) return (PokerAction.raise, raiseSize);
      }
      return (PokerAction.check, null);
    }
    final potOdds = callAmount / (pot + callAmount);
    if (equity >= potOdds) {
      if (canRaise && equity > potOdds * 1.30) {
        var raiseSize = pot * 0.65 + callAmount;
        if (raiseSize < minRaise) raiseSize = minRaise;
        if (raiseSize > stack) raiseSize = stack;
        if (raiseSize > callAmount) {
          return (PokerAction.raise, raiseSize - callAmount);
        }
      }
      return (PokerAction.call, null);
    }
    return (PokerAction.fold, null);
  }

  static (PokerAction, double?) _chaosDecide({
    required double pot,
    required double callAmount,
    required bool canCheck,
    required bool canRaise,
    required double stack,
    required Random rng,
  }) {
    final noise = rng.nextDouble() * 0.25 - 0.10;
    final pContinue = (0.70 + noise).clamp(0.50, 1.0);
    if (canCheck) {
      if (canRaise && rng.nextDouble() > 0.65) {
        final factor = 0.3 + rng.nextDouble() * 1.2;
        var raiseSize = pot * factor;
        if (raiseSize < 1) raiseSize = 1;
        if (raiseSize > stack) raiseSize = stack;
        if (raiseSize > 0) return (PokerAction.raise, raiseSize);
      }
      return (PokerAction.check, null);
    }
    if (rng.nextDouble() > pContinue) return (PokerAction.fold, null);
    if (canRaise && rng.nextDouble() > 0.75) {
      final factor = 0.3 + rng.nextDouble() * 0.7;
      var raiseSize = pot * factor;
      if (raiseSize < 1) raiseSize = 1;
      if (raiseSize > stack - callAmount) raiseSize = stack - callAmount;
      if (raiseSize > 0) return (PokerAction.raise, raiseSize);
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
}
