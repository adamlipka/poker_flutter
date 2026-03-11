import 'package:flutter/material.dart';

import '../models/card.dart' as model;
import 'card_widget.dart';

/// Row of cards with optional label.
class HandWidget extends StatelessWidget {
  const HandWidget({super.key, required this.cards, this.label});

  final List<model.Card> cards;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null && label!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: cards.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: CardWidget(card: c))).toList(),
        ),
      ],
    );
  }
}
