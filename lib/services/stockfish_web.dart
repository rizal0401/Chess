import 'dart:async';
import 'dart:math';
import 'package:chess/chess.dart' as chess;
import 'bot_difficulty.dart';

class StockfishServiceDelegate {
  Future<void> init() async {}

  Future<Map<String, String?>?> getBestMove({
    required String fen,
    required BotDifficulty difficulty,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final game = chess.Chess();
    game.load(fen);

    final moves = game.moves({'verbose': true});
    if (moves.isEmpty) return null;

    final isWhite = game.turn == chess.Color.WHITE;

    switch (difficulty) {
      case BotDifficulty.beginner:
        moves.shuffle(Random());
        final selected = moves.first as Map;
        return {
          'from': selected['from'],
          'to': selected['to'],
          'promotion': selected['promotion'],
        };

      case BotDifficulty.easy:
        moves.shuffle(Random());
        Map selected = moves.first as Map;
        for (final m in moves) {
          if ((m as Map).containsKey('captured')) {
            selected = m;
            break;
          }
        }
        return {
          'from': selected['from'],
          'to': selected['to'],
          'promotion': selected['promotion'],
        };

      case BotDifficulty.medium:
      case BotDifficulty.hard:
      case BotDifficulty.master:
        final depth = difficulty == BotDifficulty.medium ? 2 : 3;
        Map? bestMove;
        num bestEval = isWhite ? double.negativeInfinity : double.infinity;

        moves.shuffle(Random());

        for (final m in moves) {
          final moveMap = m as Map;
          game.move({
            'from': moveMap['from'],
            'to': moveMap['to'],
            if (moveMap['promotion'] != null) 'promotion': moveMap['promotion'],
          });

          final eval = _minimax(game, depth - 1, double.negativeInfinity, double.infinity, !isWhite);
          game.undo();

          if (isWhite) {
            if (eval > bestEval) {
              bestEval = eval;
              bestMove = moveMap;
            }
          } else {
            if (eval < bestEval) {
              bestEval = eval;
              bestMove = moveMap;
            }
          }
        }

        if (bestMove != null) {
          return {
            'from': bestMove['from'],
            'to': bestMove['to'],
            'promotion': bestMove['promotion'],
          };
        }

        final fallback = moves.first as Map;
        return {
          'from': fallback['from'],
          'to': fallback['to'],
          'promotion': fallback['promotion'],
        };
    }
  }

  num _minimax(chess.Chess game, int depth, num alpha, num beta, bool isMaximizing) {
    if (depth == 0 || game.game_over) {
      return _evaluateBoard(game);
    }

    final moves = game.moves({'verbose': true});
    if (moves.isEmpty) return _evaluateBoard(game);

    if (isMaximizing) {
      num maxEval = double.negativeInfinity;
      for (final m in moves) {
        final moveMap = m as Map;
        game.move({
          'from': moveMap['from'],
          'to': moveMap['to'],
          if (moveMap['promotion'] != null) 'promotion': moveMap['promotion'],
        });
        final eval = _minimax(game, depth - 1, alpha, beta, false);
        game.undo();
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      num minEval = double.infinity;
      for (final m in moves) {
        final moveMap = m as Map;
        game.move({
          'from': moveMap['from'],
          'to': moveMap['to'],
          if (moveMap['promotion'] != null) 'promotion': moveMap['promotion'],
        });
        final eval = _minimax(game, depth - 1, alpha, beta, true);
        game.undo();
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  num _evaluateBoard(chess.Chess game) {
    if (game.in_checkmate) {
      return game.turn == chess.Color.WHITE ? -10000 : 10000;
    }
    if (game.in_draw || game.in_stalemate) return 0;

    num totalValue = 0;

    final pieceValues = {
      'p': 10,
      'n': 30,
      'b': 30,
      'r': 50,
      'q': 90,
      'k': 900,
    };

    for (final piece in game.board) {
      if (piece != null) {
        final val = pieceValues[piece.type.name] ?? 0;
        if (piece.color == chess.Color.WHITE) {
          totalValue += val;
        } else {
          totalValue -= val;
        }
      }
    }
    return totalValue;
  }

  void dispose() {}
}
