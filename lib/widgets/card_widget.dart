import 'package:flutter/material.dart';

import '../models/card.dart' as model;

/// Single card: rank + suit (red for hearts/diamonds).
class CardWidget extends StatelessWidget {
  const CardWidget({super.key, required this.card});

  final model.Card card;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 44, minHeight: 60),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.rank.display,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: card.suit.isRed ? Colors.red : null,
                ),
          ),
          Text(
            card.suit.symbol,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: card.suit.isRed ? Colors.red : null,
                ),
          ),
        ],
      ),
    );
  }
}
