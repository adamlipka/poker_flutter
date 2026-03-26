import 'dart:math';

import 'package:flutter/material.dart';

import 'models/game_config.dart';
import 'models/human_vs_bot_session.dart';
import 'models/two_player_session.dart';
import 'widgets/explanations_view.dart';
import 'widgets/human_vs_bot_view.dart';
import 'widgets/settings_view.dart';
import 'widgets/two_player_view.dart';

void main() {
  runApp(const PokerApp());
}

class PokerApp extends StatelessWidget {
  const PokerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'House of Cards',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const PokerHomePage(),
    );
  }
}

class PokerHomePage extends StatefulWidget {
  const PokerHomePage({super.key});

  @override
  State<PokerHomePage> createState() => _PokerHomePageState();
}

class _PokerHomePageState extends State<PokerHomePage> {
  TwoPlayerSession? _session;
  HumanVsBotSession? _humanVsBotSession;
  int _currentHandIndex = 0;
  int _currentStageIndex = 0;
  String _seedText = '3333';
  int _numberOfHands = 5;
  double _initialCapital = 1000;
  double _potSize = 100;
  double _stake = 50;
  GameMode _gameMode = GameMode.botVsBot;
  BotType _botType = BotType.mathematician;
  int _selectedTab = 0;

  int get _seedValue => int.tryParse(_seedText) ?? 3333;

  void _reloadRandomGame() {
    _startGameWithRandomSeed();
  }

  void _startGameFromCurrentSeed() {
    _startGame(_seedValue, updateSeedText: false);
  }

  void _startGameWithRandomSeed() {
    final newSeed = Random().nextInt(999999) + 1;
    _startGame(newSeed, updateSeedText: true);
  }

  void _startGame(int seed, {required bool updateSeedText}) {
    setState(() {
      if (updateSeedText) {
        _seedText = seed.toString();
      }
      if (_gameMode == GameMode.botVsBot) {
        _session = TwoPlayerSession(
          seed: seed,
          numberOfHands: _numberOfHands,
          initialCapital: _initialCapital,
          potSize: _potSize,
          stake: _stake,
        );
        _humanVsBotSession = null;
      } else {
        _humanVsBotSession = HumanVsBotSession(
          seed: seed,
          initialCapital: _initialCapital,
          potSize: _potSize,
          stake: _stake,
          botType: _botType,
        );
        _session = null;
      }
      _currentHandIndex = 0;
      _currentStageIndex = 0;
      _selectedTab = 0;
    });
  }

  void _prevHand() {
    if (_session == null || _currentHandIndex <= 0) return;
    setState(() {
      _currentHandIndex--;
      _currentStageIndex = 0;
    });
  }

  void _nextHand() {
    if (_session == null || _currentHandIndex >= _session!.hands.length - 1) {
      return;
    }
    setState(() {
      _currentHandIndex++;
      _currentStageIndex = 0;
    });
  }

  void _prevStage() {
    if (_currentStageIndex <= 0) return;
    setState(() => _currentStageIndex--);
  }

  void _nextStage() {
    if (_session == null || _session!.hands.isEmpty) return;
    final hand = _session!.hands[_currentHandIndex];
    if (_currentStageIndex >= hand.stages.length - 1) return;
    setState(() => _currentStageIndex++);
  }

  void _onStageTapped(int index) {
    setState(() => _currentStageIndex = index);
  }

  void _humanFold() {
    if (_humanVsBotSession == null) return;
    setState(() => _humanVsBotSession!.humanFold());
  }

  void _humanCheckOrCall() {
    if (_humanVsBotSession == null) return;
    setState(() => _humanVsBotSession!.humanCheckOrCall());
  }

  void _humanRaise() {
    if (_humanVsBotSession == null) return;
    setState(() => _humanVsBotSession!.humanRaise());
  }

  void _humanNextHand() {
    if (_humanVsBotSession == null) return;
    setState(() => _humanVsBotSession!.startNextHand());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedTab,
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text(
                _gameMode == GameMode.botVsBot
                    ? 'Matematyk vs Chaotyczny'
                    : 'Ty vs ${_botType.label}',
              ),
              actions: [
                IconButton(
                  tooltip: 'Nowa rozgrywka (losowe ziarno)',
                  icon: const Icon(Icons.refresh),
                  onPressed: _reloadRandomGame,
                ),
              ],
            ),
            body: _gameMode == GameMode.botVsBot
                ? TwoPlayerView(
                    session: _session,
                    currentHandIndex: _currentHandIndex,
                    currentStageIndex: _currentStageIndex,
                    onPrevHand: _prevHand,
                    onNextHand: _nextHand,
                    onPrevStage: _prevStage,
                    onNextStage: _nextStage,
                    onStageTapped: _onStageTapped,
                    onStartGame: _startGameFromCurrentSeed,
                  )
                : HumanVsBotView(
                    session: _humanVsBotSession,
                    onStartGame: _startGameFromCurrentSeed,
                    onStartRandomGame: _startGameWithRandomSeed,
                    onFold: _humanFold,
                    onCheckOrCall: _humanCheckOrCall,
                    onRaise: _humanRaise,
                    onNextHand: _humanNextHand,
                  ),
          ),
          Scaffold(
            appBar: AppBar(title: const Text('Ustawienia rozgrywki')),
            body: SettingsView(
              gameMode: _gameMode,
              onGameModeChanged: (v) => setState(() => _gameMode = v),
              botType: _botType,
              onBotTypeChanged: (v) => setState(() => _botType = v),
              seedText: _seedText,
              onSeedTextChanged: (v) => setState(() => _seedText = v),
              numberOfHands: _numberOfHands,
              onNumberOfHandsChanged: (v) => setState(() => _numberOfHands = v),
              initialCapital: _initialCapital,
              onInitialCapitalChanged: (v) =>
                  setState(() => _initialCapital = v),
              potSize: _potSize,
              onPotSizeChanged: (v) => setState(() => _potSize = v),
              stake: _stake,
              onStakeChanged: (v) => setState(() => _stake = v),
              onStart: () {
                _startGameFromCurrentSeed();
              },
            ),
          ),
          Scaffold(
            appBar: AppBar(title: const Text('Wyjaśnienia')),
            body: const ExplanationsView(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (i) => setState(() => _selectedTab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.apps), label: 'Main'),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Ustawienia',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book),
            label: 'Wyjaśnienia',
          ),
        ],
      ),
    );
  }
}
