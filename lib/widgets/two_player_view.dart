import 'package:flutter/material.dart';

import '../models/two_player_session.dart';
import 'hand_widget.dart';

class TwoPlayerView extends StatelessWidget {
  const TwoPlayerView({
    super.key,
    this.session,
    required this.currentHandIndex,
    required this.currentStageIndex,
    required this.onPrevHand,
    required this.onNextHand,
    required this.onPrevStage,
    required this.onNextStage,
    this.onStageTapped,
    required this.onStartGame,
  });

  final TwoPlayerSession? session;
  final int currentHandIndex;
  final int currentStageIndex;
  final VoidCallback onPrevHand;
  final VoidCallback onNextHand;
  final VoidCallback onPrevStage;
  final VoidCallback onNextStage;
  final void Function(int index)? onStageTapped;
  final VoidCallback onStartGame;

  static const _phaseNames = ['Pre-flop', 'Flop', 'Turn', 'River'];

  int _clampedStageIndex(TwoPlayerHandResult hand) {
    final maxIdx = (hand.stages.length - 1).clamp(0, 999);
    return currentStageIndex.clamp(0, maxIdx);
  }

  @override
  Widget build(BuildContext context) {
    if (session == null || session!.hands.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ustaw parametry w zakładce Ustawienia, następnie rozpocznij rozgrywkę.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onStartGame,
                child: const Text('Rozpocznij rozgrywkę'),
              ),
            ],
          ),
        ),
      );
    }

    final hand = session!.hands[currentHandIndex];
    final stageIdx = _clampedStageIndex(hand);
    final stage = hand.stages[stageIdx];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _handNavigation(context),
          const SizedBox(height: 12),
          _phaseNavigation(context, hand),
          const SizedBox(height: 16),
          _cardsSection(context, hand, stage),
          const SizedBox(height: 16),
          _handInfoSection(context, hand, stage),
          const SizedBox(height: 16),
          _summarySection(context),
        ],
      ),
    );
  }

  Widget _handNavigation(BuildContext context) {
    final n = session!.hands.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rozdanie ${currentHandIndex + 1} z $n', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            FilledButton.tonal(
              onPressed: currentHandIndex > 0 ? onPrevHand : null,
              child: const Text('← Poprzednie'),
            ),
            const Spacer(),
            FilledButton.tonal(
              onPressed: currentHandIndex < n - 1 ? onNextHand : null,
              child: const Text('Następne →'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _phaseNavigation(BuildContext context, TwoPlayerHandResult hand) {
    final stageIdx = _clampedStageIndex(hand);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Faza rozgrywki', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: List.generate(_phaseNames.length, (i) {
            final isReached = i < hand.stages.length;
            final isCurrent = i == stageIdx;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Material(
                  color: isCurrent
                      ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : (isReached ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: isReached && onStageTapped != null ? () => onStageTapped!(i) : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      child: Text(
                        _phaseNames[i],
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                              color: isReached ? (isCurrent ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface) : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            FilledButton.tonal(
              onPressed: stageIdx > 0 ? onPrevStage : null,
              child: const Text('← Poprzednia faza'),
            ),
            const Spacer(),
            FilledButton.tonal(
              onPressed: stageIdx < hand.stages.length - 1 ? onNextStage : null,
              child: const Text('Następna faza →'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cardsSection(BuildContext context, TwoPlayerHandResult hand, StageResult stage) {
    final visible = hand.communityCards.take(stage.communityRevealed).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HandWidget(cards: hand.mathematicianCards, label: 'Gracz matematyczny – ${stage.handNameMath}'),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 26),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'P ≈ ${(stage.pWinMath * 100).toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'EV = ${stage.ev.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        HandWidget(cards: hand.chaoticCards, label: 'Gracz chaotyczny – ${stage.handNameChaotic}'),
        const SizedBox(height: 12),
        Text('Stół', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: Colors.grey)),
        const SizedBox(height: 4),
        if (visible.isEmpty)
          const Text('—')
        else
          HandWidget(cards: visible),
      ],
    );
  }

  Widget _handInfoSection(BuildContext context, TwoPlayerHandResult hand, StageResult stage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pula przed licytacją: ${stage.potAtStart.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium),
        if (stage.actions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Licytacja:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ...stage.actions.map((a) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(a.player == Player.mathematician ? 'Matematyk:' : 'Chaotyczny:', style: TextStyle(color: a.player == Player.mathematician ? Colors.blue : Colors.orange)),
                          const SizedBox(width: 8),
                          Flexible(child: Text(_actionLabel(a), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('pula ${a.potAfter.toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
              )),
        ],
        if (stage.winner != null) ...[
          const SizedBox(height: 6),
          Text(_winnerLabel(stage.winner!), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.grey)),
        ],
        const Divider(height: 24),
        Text('Wynik rozdania: ${_winnerLabel(hand.winner)}', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text('Kapitał po tym rozdaniu:', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
        Text('Kapitał matematyka: ${hand.capitalMath.toStringAsFixed(0)}'),
        Text('Kapitał chaotycznego: ${hand.capitalChaotic.toStringAsFixed(0)}'),
      ],
    );
  }

  Widget _summarySection(BuildContext context) {
    final s = session!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Podsumowanie rozgrywki', style: Theme.of(context).textTheme.titleMedium),
        Text('Stan po wszystkich ${s.hands.length} rozdaniach:', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
        Text('Kapitał końcowy matematyka: ${s.finalCapitalMath.toStringAsFixed(0)}'),
        Text('Kapitał końcowy chaotycznego: ${s.finalCapitalChaotic.toStringAsFixed(0)}'),
        Text('Różnica: ${(s.finalCapitalMath - s.finalCapitalChaotic).abs().toStringAsFixed(0)} ${s.finalCapitalMath >= s.finalCapitalChaotic ? '(na korzyść matematyka)' : '(na korzyść chaotycznego)'}'),
      ],
    );
  }

  String _actionLabel(BettingAction a) {
    switch (a.action) {
      case PokerAction.fold:
        return 'FOLD';
      case PokerAction.check:
        return 'CHECK';
      case PokerAction.call:
        return 'CALL';
      case PokerAction.raise:
        return 'RAISE ${a.raiseAmount?.toStringAsFixed(0) ?? ''}';
    }
  }

  String _winnerLabel(HandWinner w) {
    switch (w) {
      case HandWinner.mathematician:
        return 'Wygrywa: Matematyk';
      case HandWinner.chaotic:
        return 'Wygrywa: Gracz chaotyczny';
      case HandWinner.tie:
        return 'Remis';
    }
  }
}
