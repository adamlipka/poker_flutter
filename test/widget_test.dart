import 'package:flutter_test/flutter_test.dart';

import 'package:poker_flutter/main.dart';

void main() {
  testWidgets('Poker app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PokerApp());

    expect(find.text('Matematyk vs Chaotyczny'), findsOneWidget);
    expect(find.text('Rozpocznij rozgrywkę'), findsOneWidget);
  });
}
