import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils.dart';

class DailyWordleController extends ChangeNotifier with WidgetsBindingObserver {
  String? answer;
  List<String> guesses = [];
  String currentGuess = '';
  Map<String, LetterStatus> letterStatuses = {};
  List<List<String>> keyboardRows = [];
  bool gameOver = false;
  String? resultMessage;
  String? errorMessage;
  DateTime? startTime;
  Duration elapsed = Duration.zero;
  late final Ticker ticker;
  bool shouldTick = false;
  bool isActive = true;

  DailyWordleController() {
    ticker = Ticker(_onTick);
    WidgetsBinding.instance.addObserver(this);
    restoreGameState();
  }

  void disposeController() {
    WidgetsBinding.instance.removeObserver(this);
    ticker.stop();
    ticker.dispose();
    saveGameState();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      isActive = false;
      ticker.stop();
      saveGameState();
    } else if (state == AppLifecycleState.resumed) {
      isActive = true;

      if (shouldTick && !gameOver && !ticker.isActive) {
        ticker.start();
      }
    }
  }

  Future<void> initializeGame() async {
    final lang = await getConfig("game_lang") ?? "en";
    final pack = await readLanguagePack(lang);
    final answerWord = await getRandomAnswer(daily: true);

    keyboardRows = (pack['rows'] as List<dynamic>? ?? [])
      .map<List<String>>((row) {
        if (row is List) {
          return row.map((e) => e?.toString() ?? '').toList();
        }
        return <String>[];
    }).toList();
    answer = answerWord;
    guesses.clear();
    currentGuess = '';
    letterStatuses.clear();
    gameOver = false;
    resultMessage = null;
    errorMessage = null;
    startTime = null;
    elapsed = Duration.zero;
    shouldTick = false;
    ticker.stop();
    notifyListeners();
    saveGameState();
  }

  void updateLetterStatuses() {
    if (answer == null) return;
    letterStatuses.clear();
    for (String guess in guesses) {
      List<LetterStatus> statuses = checkGuess(guess, answer!);
      for (int i = 0; i < guess.length; i++) {
        String letter = guess[i].toLowerCase();
        LetterStatus currentStatus = letterStatuses[letter] ?? LetterStatus.absent;
        LetterStatus newStatus = statuses[i];
        if (newStatus == LetterStatus.correct ||
          (newStatus == LetterStatus.present && currentStatus != LetterStatus.correct)) {
          letterStatuses[letter] = newStatus;
        } else if (currentStatus == LetterStatus.absent) {
          letterStatuses[letter] = newStatus;
        }
      }
    }
  }

  void onLetterTap(String letter) {
    if (gameOver || currentGuess.length >= 5) return;
    currentGuess += letter.toLowerCase();
    errorMessage = null;
    if (!shouldTick) {
      shouldTick = true;
      startTime = DateTime.now();
      elapsed = Duration.zero;
      if (isActive) ticker.start();
    } else if (isActive && !ticker.isActive) {
      ticker.start();
    }
    notifyListeners();
    saveGameState();
  }

  void onBackspaceTap() {
    if (gameOver || currentGuess.isEmpty) return;
    currentGuess = currentGuess.substring(0, currentGuess.length - 1);
    errorMessage = null;
    notifyListeners();
    saveGameState();
  }

  Future<void> onEnterTap() async {
    if (gameOver || answer == null || currentGuess.length != 5) {
      if (currentGuess.length != 5) {
        errorMessage = 'Word must be 5 letters long';
        showErrorToast('Word must be 5 letters long');
        notifyListeners();
      }
      return;
    }

    bool isValid = await isValidWord(currentGuess);
    if (!isValid) {
      currentGuess = '';
      errorMessage = 'Not a valid word';
      showErrorToast('Not a valid word');
      notifyListeners();
      saveGameState();
      return;
    }

    guesses.add(currentGuess);
    currentGuess = '';
    errorMessage = null;
    updateLetterStatuses();
    if (guesses.last.toLowerCase() == answer!.toLowerCase() || guesses.length == 6) {
      gameOver = true;
      ticker.stop();
      shouldTick = false;
      resultMessage = guesses.last.toLowerCase() == answer!.toLowerCase()
        ? 'You win!'
        : 'You lose! Answer: ${answer!}';
    }
    notifyListeners();
    saveGameState();
  }

  void restartGame() {
    resetGuesses();
    saveGameState();
  }

  void resetGuesses() {
    guesses.clear();
    currentGuess = '';
    letterStatuses.clear();
    gameOver = false;
    resultMessage = null;
    errorMessage = null;
    startTime = null;
    elapsed = Duration.zero;
    shouldTick = false;
    ticker.stop();
    notifyListeners();
    saveGameState();
  }

  void _onTick(Duration elapsedTick) {
    if (shouldTick && !gameOver && startTime != null && isActive) {
      elapsed = DateTime.now().difference(startTime!);
      notifyListeners();
    }
  }

  void handleKeyEvent(KeyEvent event) {
    if (!kIsWeb || gameOver) return;
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.enter) {
        onEnterTap();
      } else if (key == LogicalKeyboardKey.backspace) {
        onBackspaceTap();
      } else if (key.keyLabel.length == 1 && RegExp(r'^[a-zA-Z]$').hasMatch(key.keyLabel)) {
        onLetterTap(key.keyLabel.toLowerCase());
      }
    }
  }

  Future<void> saveGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('daily_guesses', guesses);
    await prefs.setString('daily_currentGuess', currentGuess);
    if (answer != null) await prefs.setString('daily_answer', answer!);
    await prefs.setInt('daily_elapsed', elapsed.inSeconds);
    if (startTime != null) {
      await prefs.setInt('daily_startTime', startTime!.millisecondsSinceEpoch);
    }
    await prefs.setBool('daily_gameOver', gameOver);
    await prefs.setString('daily_resultMessage', resultMessage ?? '');
  }

  Future<void> restoreGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGuesses = prefs.getStringList('daily_guesses');
    final savedCurrentGuess = prefs.getString('daily_currentGuess');
    final savedAnswer = prefs.getString('daily_answer');
    final savedElapsed = prefs.getInt('daily_elapsed');
    final savedStartTime = prefs.getInt('daily_startTime');
    final savedGameOver = prefs.getBool('daily_gameOver');
    final savedResultMessage = prefs.getString('daily_resultMessage');

    if (savedGuesses == null || savedAnswer == null) {
      await initializeGame();
      return;
    }

    final lang = await getConfig("game_lang") ?? "en";
    final pack = await readLanguagePack(lang);

    keyboardRows = (pack['rows'] as List<dynamic>? ?? [])
      .map<List<String>>((row) {
        if (row is List) {
          return row.map((e) => e?.toString() ?? '').toList();
        }
        return <String>[];
    }).toList();
    guesses = savedGuesses;
    currentGuess = savedCurrentGuess ?? '';
    answer = savedAnswer;
    gameOver = savedGameOver ?? false;
    resultMessage = (savedResultMessage?.isEmpty ?? true) ? null : savedResultMessage;
    errorMessage = null;

    if (savedStartTime != null && savedElapsed != null && savedElapsed > 0) {
      startTime = DateTime.fromMillisecondsSinceEpoch(savedStartTime);
      elapsed = DateTime.now().difference(startTime!);
      shouldTick = true;
    } else {
      startTime = null;
      elapsed = Duration.zero;
      shouldTick = false;
    }

    updateLetterStatuses();

    ticker.stop();
    if (shouldTick && !gameOver) {
      ticker.start();
    }
    notifyListeners();
  }
}

class WordleGameView extends StatefulWidget {
  final String title;
  final DailyWordleController controller;

  const WordleGameView({super.key, required this.title, required this.controller});

  @override
  State<WordleGameView> createState() => _WordleGameViewState();
}

class _WordleGameViewState extends State<WordleGameView> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      appBar: buildAppBar(context, widget.title),
      drawer: buildDrawer(context),
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: c.handleKeyEvent,
        child: GestureDetector(
          onTap: () {
            _focusNode.requestFocus();
          },
          child: Column(
            children: [
              Expanded(
                child: buildGame(
                  guesses: c.guesses,
                  currentGuess: c.currentGuess,
                  answer: c.answer,
                  letterStatuses: c.letterStatuses,
                  keyboardRows: c.keyboardRows,
                  onLetterTap: c.gameOver ? (_) {} : c.onLetterTap,
                  onEnterTap: c.gameOver ? () {} : c.onEnterTap,
                  onBackspaceTap: c.gameOver ? () {} : c.onBackspaceTap,
                  elapsed: c.elapsed,
                  onNewGame: c.resetGuesses,
                  context: context,
                  mode: GameMode.daily,
                  gameOver: c.gameOver,
                ),
              ),
              if (c.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    c.errorMessage!,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ),
              if (c.resultMessage != null)
                Padding(
                  padding: EdgeInsetsGeometry.all(12),
                  child: Text(
                    c.resultMessage!,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                )
            ],
          ),
        )
      ),
      bottomNavigationBar: buildBottomNavigationBar(
        context,
        currentIndex: 1,
      ),
    );
  }
}

class DailyPage extends StatefulWidget {
  const DailyPage({super.key});

  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  late final DailyWordleController _controller;
  @override
  void initState() {
    super.initState();
    _controller = DailyWordleController();
  }

  @override
  void dispose() {
    _controller.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WordleGameView(
      title: "Daily Wordle",
      controller: _controller
    );
  }
}