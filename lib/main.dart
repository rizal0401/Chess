import 'package:flutter/material.dart';
import 'dart:async';
import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'dart:math';
import 'services/stockfish_service.dart';

enum GameMode { pvp, playAsWhite, playAsBlack }

void main() {
  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Chess',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _isCountDown = false;
  int _selectedSeconds = 300;
  GameMode _selectedMode = GameMode.pvp;
  BotDifficulty _selectedDifficulty = BotDifficulty.medium;

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int? _parseCustomTime(String text) {
    final parts = text.split(':');
    if (parts.length != 2) return null;
    final minutes = int.tryParse(parts[0].trim());
    final seconds = int.tryParse(parts[1].trim());
    if (minutes == null || seconds == null) return null;
    if (minutes < 0 || seconds < 0 || seconds >= 60) return null;
    final totalSeconds = minutes * 60 + seconds;
    if (totalSeconds <= 0) return null;
    return totalSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local Chess'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Select Game Mode:', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Padding(padding: EdgeInsets.all(8.0), child: Text('PvP', style: TextStyle(fontSize: 18))),
                  selected: _selectedMode == GameMode.pvp,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedMode = GameMode.pvp);
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Padding(padding: EdgeInsets.all(8.0), child: Text('vs Bot (White)', style: TextStyle(fontSize: 18))),
                  selected: _selectedMode == GameMode.playAsWhite,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedMode = GameMode.playAsWhite);
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Padding(padding: EdgeInsets.all(8.0), child: Text('vs Bot (Black)', style: TextStyle(fontSize: 18))),
                  selected: _selectedMode == GameMode.playAsBlack,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedMode = GameMode.playAsBlack);
                  },
                ),
              ],
            ),
            if (_selectedMode != GameMode.pvp) ...[
              const SizedBox(height: 24),
              const Text('Select Bot Difficulty:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: BotDifficulty.values.map((difficulty) {
                    final isSelected = _selectedDifficulty == difficulty;
                    return ChoiceChip(
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedDifficulty = difficulty);
                      },
                      label: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${difficulty.label} (${difficulty.elo} Elo)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              difficulty.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white70 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 30),
            const Text('Select Timer Mode:', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Padding(padding: EdgeInsets.all(8.0), child: Text('Count Up', style: TextStyle(fontSize: 18))),
                  selected: !_isCountDown,
                  onSelected: (selected) {
                    if (selected) setState(() => _isCountDown = false);
                  },
                ),
                const SizedBox(width: 20),
                ChoiceChip(
                  label: const Padding(padding: EdgeInsets.all(8.0), child: Text('Count Down', style: TextStyle(fontSize: 18))),
                  selected: _isCountDown,
                  onSelected: (selected) {
                    if (selected) setState(() => _isCountDown = true);
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 120,
              child: _isCountDown 
                  ? Column(
                      children: [
                        const Text('Select Duration:', style: TextStyle(fontSize: 20)),
                        const SizedBox(height: 10),
                        DropdownButton<int>(
                          value: [60, 180, 300, 600].contains(_selectedSeconds) ? _selectedSeconds : -1,
                          items: [
                            const DropdownMenuItem(value: 60, child: Text('1 min', style: TextStyle(fontSize: 18))),
                            const DropdownMenuItem(value: 180, child: Text('3 min', style: TextStyle(fontSize: 18))),
                            const DropdownMenuItem(value: 300, child: Text('5 min', style: TextStyle(fontSize: 18))),
                            const DropdownMenuItem(value: 600, child: Text('10 min', style: TextStyle(fontSize: 18))),
                            DropdownMenuItem(
                              value: -1, 
                              child: Text(
                                [60, 180, 300, 600].contains(_selectedSeconds) 
                                    ? 'Custom...' 
                                    : 'Custom (${_formatTime(_selectedSeconds)})', 
                                style: const TextStyle(fontSize: 18)
                              )
                            ),
                          ],
                          onChanged: (value) async {
                            if (value == -1) {
                              final int? custom = await showDialog<int>(
                                context: context,
                                builder: (context) {
                                  final TextEditingController controller = TextEditingController(
                                    text: _formatTime(_selectedSeconds)
                                  );
                                  String? errorMessage;
                                  return StatefulBuilder(
                                    builder: (context, setDialogState) {
                                      return AlertDialog(
                                        title: const Text('Custom Timer'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(
                                              controller: controller,
                                              keyboardType: TextInputType.datetime,
                                              autofocus: true,
                                              decoration: InputDecoration(
                                                labelText: 'Duration (MM:SS)',
                                                hintText: 'e.g. 01:30',
                                                errorText: errorMessage,
                                              ),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              final int? val = _parseCustomTime(controller.text);
                                              if (val != null) {
                                                Navigator.pop(context, val);
                                              } else {
                                                setDialogState(() {
                                                  errorMessage = 'Invalid format. Use MM:SS (e.g., 01:30)';
                                                });
                                              }
                                            },
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      );
                                    }
                                  );
                                }
                              );
                              if (custom != null) {
                                setState(() => _selectedSeconds = custom);
                              }
                            } else if (value != null) {
                              setState(() => _selectedSeconds = value);
                            }
                          },
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChessGameScreen(
                      isCountDown: _isCountDown,
                      selectedSeconds: _selectedSeconds,
                      gameMode: _selectedMode,
                      botDifficulty: _selectedDifficulty,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Text('Start Game', style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChessGameScreen extends StatefulWidget {
  final bool isCountDown;
  final int selectedSeconds;
  final GameMode gameMode;
  final BotDifficulty botDifficulty;

  const ChessGameScreen({
    super.key,
    required this.isCountDown,
    required this.selectedSeconds,
    required this.gameMode,
    this.botDifficulty = BotDifficulty.medium,
  });

  @override
  State<ChessGameScreen> createState() => _ChessGameScreenState();
}

class _ChessGameScreenState extends State<ChessGameScreen> {
  late ChessBoardController _boardController;
  final StockfishService _stockfishService = StockfishService();

  Timer? _gameTimer;
  late int _whiteTime;
  late int _blackTime;
  bool _gameStarted = false;
  HintArrow? _hintArrow;
  bool _isGettingHint = false;

  @override
  void initState() {
    super.initState();
    _boardController = ChessBoardController();
    _boardController.addListener(_onBoardChanged);
    if (widget.gameMode != GameMode.pvp) {
      _stockfishService.init();
    }
    if (widget.isCountDown) {
      _whiteTime = widget.selectedSeconds;
      _blackTime = widget.selectedSeconds;
    } else {
      _whiteTime = 0;
      _blackTime = 0;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _makeBotMoveIfNecessary();
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _stockfishService.dispose();
    _boardController.dispose();
    super.dispose();
  }

  void _onBoardChanged() {
    _hintArrow = null;

    if (!_gameStarted && _boardController.moveCount > 0) {
      _startTimer();
    }
    
    if (_boardController.isGameOver) {
      _showGameOverDialog();
    }
    
    if (mounted) {
      setState(() {});
    }

    _makeBotMoveIfNecessary();
  }

  bool _isBotThinking = false;

  bool _isBotTurn() {
    if (_boardController.isGameOver) return false;
    if (widget.gameMode == GameMode.pvp) return false;
    
    if (widget.gameMode == GameMode.playAsWhite && _boardController.playerColor == PlayerColor.black) {
      return true;
    }
    if (widget.gameMode == GameMode.playAsBlack && _boardController.playerColor == PlayerColor.white) {
      return true;
    }
    return false;
  }

  void _makeBotMoveIfNecessary() async {
    if (_isBotThinking) return;
    if (!_isBotTurn()) return;

    _isBotThinking = true;
    if (mounted) setState(() {});

    final stopwatch = Stopwatch()..start();

    // Call Stockfish service to get best move based on chosen difficulty
    final moveMap = await _stockfishService.getBestMove(
      fen: _boardController.fen,
      difficulty: widget.botDifficulty,
    );

    // Enforce smooth minimum thinking delay (400ms) so moves don't feel jarringly instant
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < 400) {
      await Future.delayed(Duration(milliseconds: 400 - elapsed));
    }

    if (!mounted || !_isBotTurn()) {
      _isBotThinking = false;
      if (mounted) setState(() {});
      return;
    }

    if (moveMap != null) {
      _boardController.makeMove(
        from: moveMap['from']!,
        to: moveMap['to']!,
        promotion: moveMap['promotion'],
      );
    } else {
      // Fallback: pick random move if Stockfish output wasn't available
      final moves = _boardController.game.moves({'verbose': true});
      if (moves.isNotEmpty) {
        moves.shuffle(Random());
        var selectedMove = moves.first;
        for (var m in moves) {
          if ((m as Map).containsKey('captured')) {
            selectedMove = m;
            break;
          }
        }

        final moveMapFallback = selectedMove as Map;
        _boardController.makeMove(
          from: moveMapFallback['from'],
          to: moveMapFallback['to'],
          promotion: moveMapFallback['promotion'],
        );
      }
    }
    _isBotThinking = false;
    if (mounted) setState(() {});
  }

  void _startTimer() {
    _gameStarted = true;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_boardController.isGameOver) {
        timer.cancel();
        return;
      }
      setState(() {
        if (widget.isCountDown) {
          if (_boardController.playerColor == PlayerColor.white) {
            if (_whiteTime > 0) _whiteTime--;
          } else {
            if (_blackTime > 0) _blackTime--;
          }
          
          if (_whiteTime <= 0 || _blackTime <= 0) {
            timer.cancel();
            _showTimeoutDialog(_whiteTime <= 0 ? "White" : "Black");
          }
        } else {
          if (_boardController.playerColor == PlayerColor.white) {
            _whiteTime++;
          } else {
            _blackTime++;
          }
        }
      });
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _resetGame() {
    _gameTimer?.cancel();
    _boardController.resetBoard();
    setState(() {
      _hintArrow = null;
      _gameStarted = false;
      if (widget.isCountDown) {
        _whiteTime = widget.selectedSeconds;
        _blackTime = widget.selectedSeconds;
      } else {
        _whiteTime = 0;
        _blackTime = 0;
      }
    });
    
    _makeBotMoveIfNecessary();
  }

  void _undoMove() {
    if (_isBotThinking) return;
    if (_boardController.moveCount == 0) return;

    setState(() {
      _hintArrow = null;
    });

    if (widget.gameMode == GameMode.pvp) {
      _boardController.undo();
    } else {
      if (_boardController.moveCount >= 2) {
        _boardController.undo(notify: false);
        _boardController.undo();
      } else {
        _boardController.undo();
      }
    }

    if (_gameStarted && (_gameTimer == null || !_gameTimer!.isActive) && !_boardController.isGameOver) {
      _startTimer();
    }
  }

  void _getHint() async {
    if (_isGettingHint || _isBotThinking || _boardController.isGameOver) return;
    if (_isBotTurn()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Wait for the bot to finish its move!"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isGettingHint = true;
    });

    final bestMove = await _stockfishService.getBestMove(
      fen: _boardController.fen,
      difficulty: BotDifficulty.master,
    );

    if (!mounted) return;

    setState(() {
      _isGettingHint = false;
    });

    if (bestMove != null && bestMove['from'] != null && bestMove['to'] != null) {
      final from = bestMove['from']!;
      final to = bestMove['to']!;
      setState(() {
        _hintArrow = HintArrow(startSquare: from, endSquare: to);
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("💡 Hint: Recommended move from $from to $to"),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No hint available for this position."),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String get _turnText => _boardController.playerColor == PlayerColor.white ? "White's Turn" : "Black's Turn";

  void _showGameOverDialog() {
    String message = "Game Over!";
    if (_boardController.isCheckmate) {
      String winner = _boardController.playerColor == PlayerColor.white ? "Black" : "White";
      message = "Checkmate! $winner wins.";
    } else if (_boardController.isDraw) {
      message = "Draw!";
    } else if (_boardController.isStalemate) {
      message = "Stalemate!";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Widget dialogContent = AlertDialog(
          title: const Text('Game Over'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('Undo'),
              onPressed: () {
                Navigator.of(context).pop();
                _undoMove();
              },
            ),
            TextButton(
              child: const Text('Play Again'),
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
            ),
          ],
        );

        if (widget.gameMode == GameMode.pvp && _boardController.playerColor == PlayerColor.black) {
           dialogContent = RotatedBox(
            quarterTurns: 2,
            child: dialogContent,
          );
        }

        return dialogContent;
      },
    );
  }

  void _showTimeoutDialog(String loser) {
    String winner = loser == "White" ? "Black" : "White";
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Widget dialogContent = AlertDialog(
          title: const Text('Time\'s Up!'),
          content: Text('$loser ran out of time. $winner wins!'),
          actions: [
            TextButton(
              child: const Text('Play Again'),
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
            ),
          ],
        );

        if (widget.gameMode == GameMode.pvp && _boardController.playerColor == PlayerColor.black) {
           dialogContent = RotatedBox(
            quarterTurns: 2,
            child: dialogContent,
          );
        }

        return dialogContent;
      },
    );
  }

  Widget _buildTimerCard({required bool isActive, required int timeInSeconds, required bool isWhite}) {
    final displayTime = _formatTime(timeInSeconds);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive 
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive 
              ? colorScheme.primary 
              : colorScheme.outline.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ] : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 12,
            color: isActive ? Colors.greenAccent : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            isWhite ? "White: $displayTime" : "Black: $displayTime",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isCheck = _boardController.isInCheck;
    bool isWhiteTurn = _boardController.playerColor == PlayerColor.white;
    bool isPvP = widget.gameMode == GameMode.pvp;
    
    Widget turnIndicator = Text(
      _turnText,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: isCheck ? Colors.red : null,
      ),
    );

    if (isPvP && !isWhiteTurn) {
      turnIndicator = RotatedBox(
        quarterTurns: 2,
        child: turnIndicator,
      );
    }

    Widget checkIndicator = const Text(
      'CHECK',
      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20),
    );

    if (isPvP && !isWhiteTurn && isCheck) {
      checkIndicator = RotatedBox(
        quarterTurns: 2,
        child: checkIndicator,
      );
    }

    Widget blackTimerWidget = _buildTimerCard(
      isActive: _gameStarted && !_boardController.isGameOver && !isWhiteTurn,
      timeInSeconds: _blackTime,
      isWhite: false,
    );
    if (isPvP && !isWhiteTurn) {
      blackTimerWidget = RotatedBox(
        quarterTurns: 2,
        child: blackTimerWidget,
      );
    }

    Widget whiteTimerWidget = _buildTimerCard(
      isActive: _gameStarted && !_boardController.isGameOver && isWhiteTurn,
      timeInSeconds: _whiteTime,
      isWhite: true,
    );
    if (isPvP && !isWhiteTurn) {
      whiteTimerWidget = RotatedBox(
        quarterTurns: 2,
        child: whiteTimerWidget,
      );
    }

    Widget topTimer = widget.gameMode == GameMode.playAsBlack ? whiteTimerWidget : blackTimerWidget;
    Widget bottomTimer = widget.gameMode == GameMode.playAsBlack ? blackTimerWidget : whiteTimerWidget;
    
    final isBotMode = widget.gameMode != GameMode.pvp;
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Local Chess'),
            if (isBotMode)
              Text(
                'vs Bot (${widget.botDifficulty.label} - ${widget.botDifficulty.elo} Elo)',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              )
            else
              const Text(
                'Player vs Player',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
          tooltip: 'Back to Menu',
        ),
        actions: [
          IconButton(
            icon: _isGettingHint
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                  )
                : const Icon(Icons.lightbulb_outline, color: Colors.amber),
            onPressed: (_isBotThinking || _isBotTurn() || _boardController.isGameOver) ? null : _getHint,
            tooltip: 'Get Move Hint',
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: (_isBotThinking || _boardController.moveCount == 0) ? null : _undoMove,
            tooltip: 'Undo Move',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
            tooltip: 'Restart Game',
          )
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: turnIndicator,
                ),
                if (_isBotThinking)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Stockfish is thinking...',
                          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.amberAccent),
                        ),
                      ],
                    ),
                  ),
                if (isCheck) checkIndicator,
                const SizedBox(height: 16),
                topTimer,
                const SizedBox(height: 16),
                Flexible(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: IgnorePointer(
                        ignoring: _isBotThinking || _isBotTurn() || _boardController.isGameOver,
                        child: AdvancedChessBoard(
                          controller: _boardController,
                          boardTheme: BoardTheme.brown,
                          pieceQuarterTurns: isPvP ? (isWhiteTurn ? 0 : 2) : 0,
                          boardOrientation: widget.gameMode == GameMode.playAsBlack ? PlayerColor.black : PlayerColor.white,
                          hintArrow: _hintArrow,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                bottomTimer,
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
