import 'dart:math';

import 'package:flutter/material.dart';

import 'models/two_player_session.dart';
import 'widgets/explanations_view.dart';
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
      title: 'Poker Helper',
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
  int _currentHandIndex = 0;
  int _currentStageIndex = 0;
  String _seedText = '3333';
  int _numberOfHands = 5;
  double _initialCapital = 1000;
  double _potSize = 100;
  double _stake = 50;
  int _selectedTab = 0;

  int get _seedValue => int.tryParse(_seedText) ?? 3333;

  void _reloadRandomGame() {
    setState(() {
      final rnd = Random();
      _seedText = (rnd.nextInt(999999) + 1).toString();
    });
    _startGame();
  }

  void _startGame() {
    setState(() {
      _session = TwoPlayerSession(
        seed: _seedValue,
        numberOfHands: _numberOfHands,
        initialCapital: _initialCapital,
        potSize: _potSize,
        stake: _stake,
      );
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
    if (_session == null || _currentHandIndex >= _session!.hands.length - 1) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedTab,
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text('Matematyk vs Chaotyczny'),
              actions: [
                IconButton(
                  tooltip: 'Nowa rozgrywka (losowe ziarno)',
                  icon: const Icon(Icons.refresh),
                  onPressed: _reloadRandomGame,
                ),
              ],
            ),
            body: TwoPlayerView(
              session: _session,
              currentHandIndex: _currentHandIndex,
              currentStageIndex: _currentStageIndex,
              onPrevHand: _prevHand,
              onNextHand: _nextHand,
              onPrevStage: _prevStage,
              onNextStage: _nextStage,
              onStageTapped: _onStageTapped,
              onStartGame: _startGame,
            ),
          ),
          Scaffold(
            appBar: AppBar(title: const Text('Ustawienia rozgrywki')),
            body: SettingsView(
              seedText: _seedText,
              onSeedTextChanged: (v) => setState(() => _seedText = v),
              numberOfHands: _numberOfHands,
              onNumberOfHandsChanged: (v) => setState(() => _numberOfHands = v),
              initialCapital: _initialCapital,
              onInitialCapitalChanged: (v) => setState(() => _initialCapital = v),
              potSize: _potSize,
              onPotSizeChanged: (v) => setState(() => _potSize = v),
              stake: _stake,
              onStakeChanged: (v) => setState(() => _stake = v),
              onStart: () {
                _startGame();
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
          NavigationDestination(
            icon: Icon(Icons.apps),
            label: 'Main',
          ),
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
