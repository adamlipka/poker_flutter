import 'package:flutter/material.dart';

/// Zakładka Wyjaśnienia: metoda gry graczy i pojęcia rozgrywki.
class ExplanationsView extends StatelessWidget {
  const ExplanationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Metoda gry gracza matematyka', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Matematyk na każdym etapie porównuje equity (szacowane P(wygrana)) z pot odds – czyli stosunkiem kosztu calla do puli. Jeśli equity > pot odds, opłaca się wejść lub podbić. Przy dużej przewadze raise\'uje na ~65% puli, żeby wyciągnąć pieniądze z przeciwnika. Dąży do maksymalizacji zysku w długim okresie.',
        ),
        const SizedBox(height: 20),
        Text('Metoda gry gracza chaotycznego', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Chaotyczny to naiwny optymista – zawsze widzi potencjał w swoich kartach i prawie zawsze wchodzi do gry (minimum 50% szans na kontynuację, zazwyczaj 70–85%). Siła ręki nie wpływa na jego decyzję o pasowaniu – pasuje tylko z kaprysu. Błędy są fałszywie pozytywne: gra za słabe układy i traci na showdownach. Czasem raise\'uje losowo (blef z emocji). To odzwierciedla typowego amatora – zbyt optymistycznego, by się wycofać.',
        ),
        const SizedBox(height: 20),
        Text('Struktura rozgrywki – Texas Hold\'em heads-up', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _bullet('Blindy – obowiązkowe zakłady przed kartami: Small Blind (SB) i Big Blind (BB = 2×SB). Rotują co rozdanie.'),
        _bullet('Fazy: Pre-flop (karty graczy), Flop (3 karty wspólne), Turn (+1), River (+1). W każdej fazie odbywa się pełna runda licytacji.'),
        _bullet('CHECK – gracz nie dopłaca, gdy nie ma aktywnego zakładu; CALL – wyrównanie zakładu; RAISE – podbicie; FOLD – rezygnacja (pula do przeciwnika).'),
        _bullet('Kolejność: pre-flop SB działa pierwszy; flop/turn/river – gracz nie-dealer działa pierwszy.'),
        _bullet('Pot odds = callAmount / (pula + callAmount). Jeśli equity > pot odds, CALL jest opłacalny.'),
        _bullet('EV (wartość oczekiwana) = P(wygrana)×(pula+BB) − P(przegrana)×BB. Dodatnie EV = dobra decyzja w długim okresie.'),
        _bullet('Showdown – gdy obaj dotrą do river, karty porównywane; lepsza 5-kartowa ręka z 7 dostępnych wygrywa pulę.'),
      ],
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
