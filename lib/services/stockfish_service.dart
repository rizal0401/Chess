import 'dart:async';
import 'bot_difficulty.dart';
export 'bot_difficulty.dart';

import 'stockfish_stub.dart'
    if (dart.library.io) 'stockfish_io.dart'
    if (dart.library.js_interop) 'stockfish_web.dart'
    if (dart.library.html) 'stockfish_web.dart' as impl;

class StockfishService {
  final impl.StockfishServiceDelegate _delegate = impl.StockfishServiceDelegate();

  Future<void> init() => _delegate.init();

  Future<Map<String, String?>?> getBestMove({
    required String fen,
    required BotDifficulty difficulty,
    Duration timeout = const Duration(seconds: 10),
  }) =>
      _delegate.getBestMove(
        fen: fen,
        difficulty: difficulty,
        timeout: timeout,
      );

  void dispose() => _delegate.dispose();
}
