import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_config.dart';

/// Parametry rozgrywki i przycisk „Rozpocznij rozgrywkę” – używane w zakładce Ustawienia.
class SettingsView extends StatelessWidget {
  const SettingsView({
    super.key,
    required this.gameMode,
    required this.onGameModeChanged,
    required this.botType,
    required this.onBotTypeChanged,
    required this.seedText,
    required this.onSeedTextChanged,
    required this.numberOfHands,
    required this.onNumberOfHandsChanged,
    required this.initialCapital,
    required this.onInitialCapitalChanged,
    required this.potSize,
    required this.onPotSizeChanged,
    required this.stake,
    required this.onStakeChanged,
    required this.onStart,
  });

  final GameMode gameMode;
  final ValueChanged<GameMode> onGameModeChanged;
  final BotType botType;
  final ValueChanged<BotType> onBotTypeChanged;
  final String seedText;
  final ValueChanged<String> onSeedTextChanged;
  final int numberOfHands;
  final ValueChanged<int> onNumberOfHandsChanged;
  final double initialCapital;
  final ValueChanged<double> onInitialCapitalChanged;
  final double potSize;
  final ValueChanged<double> onPotSizeChanged;
  final double stake;
  final ValueChanged<double> onStakeChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Tryb gry', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SegmentedButton<GameMode>(
          segments: const [
            ButtonSegment<GameMode>(
              value: GameMode.botVsBot,
              label: Text('Bot vs Bot'),
            ),
            ButtonSegment<GameMode>(
              value: GameMode.humanVsBot,
              label: Text('Human vs Bot'),
            ),
          ],
          selected: {gameMode},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) onGameModeChanged(selection.first);
          },
        ),
        const SizedBox(height: 16),
        if (gameMode == GameMode.humanVsBot) ...[
          const Text('Typ bota', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<BotType>(
            segments: const [
              ButtonSegment<BotType>(
                value: BotType.mathematician,
                label: Text('Matematyk'),
              ),
              ButtonSegment<BotType>(
                value: BotType.chaotic,
                label: Text('Chaotyczny'),
              ),
            ],
            selected: {botType},
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) onBotTypeChanged(selection.first);
            },
          ),
          const SizedBox(height: 20),
        ],
        const Text('Ziarno', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey(seedText),
                initialValue: seedText,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (v) {
                  final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits != v) {
                    onSeedTextChanged(digits);
                  } else {
                    onSeedTextChanged(v);
                  }
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ziarno',
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () =>
                  onSeedTextChanged('${Random().nextInt(999999) + 1}'),
              child: const Text('Losuj'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Ziarno RNG do powtarzalności rozdań. Tylko cyfry. „Losuj” ustawia losowe ziarno.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (gameMode == GameMode.botVsBot) ...[
          const SizedBox(height: 24),
          const Text(
            'Liczba rozdań',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              Text('$numberOfHands'),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: numberOfHands > 1
                    ? () => onNumberOfHandsChanged(numberOfHands - 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: numberOfHands < 20
                    ? () => onNumberOfHandsChanged(numberOfHands + 1)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Ile rozdań rozegrać w jednej sesji (1–20).',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Kapitał i stawki',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialCapital.toString(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => onInitialCapitalChanged(
            double.tryParse(v.replaceAll(',', '.')) ?? initialCapital,
          ),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Kapitał początkowy',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: potSize.toString(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => onPotSizeChanged(
            double.tryParse(v.replaceAll(',', '.')) ?? potSize,
          ),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Pula startowa (ante)',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: stake.toString(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) =>
              onStakeChanged(double.tryParse(v.replaceAll(',', '.')) ?? stake),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Small Blind (BB = 2×)',
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onStart,
          child: const Text('Rozpocznij rozgrywkę'),
        ),
      ],
    );
  }
}
