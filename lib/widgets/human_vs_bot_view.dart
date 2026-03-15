import 'package:flutter/material.dart';

import '../models/human_vs_bot_session.dart';
import '../models/two_player_session.dart' show PokerAction;
import 'card_widget.dart';
import 'hand_widget.dart';

class HumanVsBotView extends StatelessWidget {
  const HumanVsBotView({
    super.key,
    this.session,
    required this.onStartGame,
    required this.onStartRandomGame,
    required this.onFold,
    required this.onCheckOrCall,
    required this.onRaise,
    required this.onNextHand,
  });

  final HumanVsBotSession? session;
  final VoidCallback onStartGame;
  final VoidCallback onStartRandomGame;
  final VoidCallback onFold;
  final VoidCallback onCheckOrCall;
  final VoidCallback onRaise;
  final VoidCallback onNextHand;

  static const _phaseNames = ['Pre-flop', 'Flop', 'Turn', 'River'];

  @override
  Widget build(BuildContext context) {
    if (session == null || !session!.hasCurrentHand) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ustaw parametry gry i rozpocznij tryb Human vs Bot.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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

    final s = session!;
    final stage = s.stageForUi;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context, s),
          const SizedBox(height: 12),
          _phaseNavigation(context, s),
          const SizedBox(height: 16),
          _cardsSection(context, s, stage),
          const SizedBox(height: 16),
          _bettingSection(context, s, stage),
          const SizedBox(height: 16),
          _actionsSection(context, s),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, HumanVsBotSession s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rozdanie ${s.handNumber}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                'Aktualna pula',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                s.pot.toStringAsFixed(0),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _phaseNavigation(BuildContext context, HumanVsBotSession s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Faza rozgrywki',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(_phaseNames.length, (i) {
            final isReached = i <= s.currentStageIndex;
            final isCurrent = i == s.currentStageIndex;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.5)
                        : (isReached
                              ? Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest
                              : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _phaseNames[i],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: isCurrent
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isReached
                          ? (isCurrent
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface)
                          : Theme.of(context).colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _cardsSection(
    BuildContext context,
    HumanVsBotSession s,
    HumanStageResult stage,
  ) {
    final visibleCommunity = s.visibleCommunityCards;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HandWidget(
              cards: s.humanCards,
              label:
                  'Ty (${s.humanBlindLabel}, kapitał ${s.humanCapital.toStringAsFixed(0)}) - ${stage.handNameHuman}',
            ),
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
                          'P ≈ ${(stage.pWinHuman * 100).toStringAsFixed(1)}%',
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
        Text(
          s.revealBotCards
              ? 'Bot (${s.botBlindLabel}, kapitał ${s.botCapital.toStringAsFixed(0)}) - ${stage.handNameBot}'
              : 'Bot (${s.botBlindLabel}, kapitał ${s.botCapital.toStringAsFixed(0)}) - karty ukryte',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: s.revealBotCards
              ? s.botCards
                    .map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CardWidget(card: c),
                      ),
                    )
                    .toList()
              : List.generate(
                  2,
                  (_) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _hiddenCard(context),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Text(
          'Stół',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        if (visibleCommunity.isEmpty)
          const Text('—')
        else
          HandWidget(cards: visibleCommunity),
      ],
    );
  }

  Widget _bettingSection(
    BuildContext context,
    HumanVsBotSession s,
    HumanStageResult stage,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pula przed licytacją: ${stage.potAtStart.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (stage.actions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Licytacja:',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          ...stage.actions.map(
            (a) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          a.actor == HumanBotActor.human ? 'Ty:' : 'Bot:',
                          style: TextStyle(
                            color: a.actor == HumanBotActor.human
                                ? Colors.blue
                                : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _actionLabel(a),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'pula ${a.potAfter.toStringAsFixed(0)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 6),
        if (s.isHandOver)
          Text(
            s.handResultLabel,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          )
        else
          Text(
            s.actorToAct == HumanBotActor.human ? 'Twój ruch' : 'Ruch bota...',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
      ],
    );
  }

  Widget _actionsSection(BuildContext context, HumanVsBotSession s) {
    if (s.isHandOver) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stan meczu',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(s.matchResultLabel),
          const SizedBox(height: 10),
          if (!s.isMatchOver)
            FilledButton(
              onPressed: onNextHand,
              child: const Text('Następne rozdanie'),
            )
          else
            FilledButton(
              onPressed: onStartRandomGame,
              child: const Text('Nowa gra'),
            ),
        ],
      );
    }

    final callSubtitle = s.canHumanCheck
        ? 'koszt 0'
        : 'koszt ${s.humanCallCost.toStringAsFixed(0)}';
    final raiseSubtitle = 'koszt ${s.humanRaiseTotalCost.toStringAsFixed(0)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aktualna pula: ${s.pot.toStringAsFixed(0)}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (s.isHumanTurn)
                Text(
                  'Do calla: ${s.humanCallCost.toStringAsFixed(0)} | Raise łącznie: ${s.humanRaiseTotalCost.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: s.canHumanFold ? onFold : null,
                child: _actionButtonText('Fold', 'koszt 0'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonal(
                onPressed: s.isHumanTurn ? onCheckOrCall : null,
                child: _actionButtonText(s.humanCheckOrCallLabel, callSubtitle),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: s.canHumanRaise ? onRaise : null,
                child: _actionButtonText('Raise', raiseSubtitle),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButtonText(String title, String subtitle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _hiddenCard(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 44, minHeight: 60),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.question_mark,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  String _actionLabel(HumanBettingAction action) {
    switch (action.action) {
      case PokerAction.fold:
        return 'FOLD';
      case PokerAction.check:
        return 'CHECK';
      case PokerAction.call:
        return 'CALL';
      case PokerAction.raise:
        return 'RAISE ${action.raiseAmount?.toStringAsFixed(0) ?? ''}';
    }
  }
}
