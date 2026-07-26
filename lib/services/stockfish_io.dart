import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:stockfish/stockfish.dart';
import 'bot_difficulty.dart';

class StockfishServiceDelegate {
  Stockfish? _stockfish;
  StreamSubscription<String>? _stdoutSubscription;
  Completer<String?>? _bestMoveCompleter;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized && _stockfish != null) return;

    try {
      _stockfish = Stockfish();
      _stdoutSubscription = _stockfish!.stdout.listen(_onStdout);
      _isInitialized = true;

      _stockfish!.stdin = 'uci\n';
      _stockfish!.stdin = 'isready\n';
    } catch (e) {
      debugPrint('Error initializing Stockfish Native: $e');
    }
  }

  void _onStdout(String line) {
    final trimmed = line.trim();
    if (trimmed.startsWith('bestmove')) {
      final parts = trimmed.split(' ');
      if (parts.length >= 2) {
        final moveStr = parts[1];
        if (_bestMoveCompleter != null && !_bestMoveCompleter!.isCompleted) {
          _bestMoveCompleter!.complete(moveStr == '(none)' ? null : moveStr);
        }
      }
    }
  }

  Future<Map<String, String?>?> getBestMove({
    required String fen,
    required BotDifficulty difficulty,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!_isInitialized || _stockfish == null) {
      await init();
    }
    if (_stockfish == null) return null;

    _bestMoveCompleter = Completer<String?>();

    _stockfish!.stdin = 'setoption name Skill Level value ${difficulty.skillLevel}\n';
    if (difficulty != BotDifficulty.master) {
      _stockfish!.stdin = 'setoption name UCI_LimitStrength value true\n';
      _stockfish!.stdin = 'setoption name UCI_Elo value ${difficulty.elo}\n';
    } else {
      _stockfish!.stdin = 'setoption name UCI_LimitStrength value false\n';
    }
    _stockfish!.stdin = 'isready\n';
    _stockfish!.stdin = 'position fen $fen\n';
    _stockfish!.stdin = 'go depth ${difficulty.maxDepth}\n';

    try {
      final bestMoveStr = await _bestMoveCompleter!.future.timeout(
        timeout,
        onTimeout: () {
          debugPrint('Stockfish getBestMove timed out.');
          return null;
        },
      );

      if (bestMoveStr == null || bestMoveStr.length < 4) {
        return null;
      }

      final from = bestMoveStr.substring(0, 2);
      final to = bestMoveStr.substring(2, 4);
      final promotion = bestMoveStr.length >= 5 ? bestMoveStr.substring(4, 5) : null;

      return {
        'from': from,
        'to': to,
        'promotion': promotion,
      };
    } catch (e) {
      debugPrint('Error getting best move from Stockfish Native: $e');
      return null;
    }
  }

  void dispose() {
    _stdoutSubscription?.cancel();
    _stdoutSubscription = null;
    _stockfish?.dispose();
    _stockfish = null;
    _isInitialized = false;
  }
}
