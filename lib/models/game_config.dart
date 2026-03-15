enum GameMode { botVsBot, humanVsBot }

enum BotType { mathematician, chaotic }

extension GameModeLabel on GameMode {
  String get label {
    switch (this) {
      case GameMode.botVsBot:
        return 'Bot vs Bot';
      case GameMode.humanVsBot:
        return 'Human vs Bot';
    }
  }
}

extension BotTypeLabel on BotType {
  String get label {
    switch (this) {
      case BotType.mathematician:
        return 'Matematyk';
      case BotType.chaotic:
        return 'Chaotyczny';
    }
  }
}
