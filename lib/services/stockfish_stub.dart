import 'bot_difficulty.dart';

class StockfishServiceDelegate {
  Future<void> init() async {}

  Future<Map<String, String?>?> getBestMove({
    required String fen,
    required BotDifficulty difficulty,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return null;
  }

  void dispose() {}
}
