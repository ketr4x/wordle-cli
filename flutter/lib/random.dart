import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils.dart';

class RandomWordleController extends ChangeNotifier with WidgetsBindingObserver {
  String? answer;
  List<String> guesses = [];
  String currentGuess = '';
  Map<String, LetterStatus> letterStatuses = {};
  List<String> keyboardLayout = [];
  bool gameOver = false;
  String? resultMessage;
  String? errorMessage;
  DateTime? startTime;
  Duration elapsed = Duration.zero;
  late final Ticker ticker;
  bool shouldTick = false;
  bool isActive = true;

  RandomWordleController() {
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
    final letters = pack['letters'] as List<dynamic>;
    final answerWord = await getRandomAnswer(daily: false);

    answer = answerWord;
    keyboardLayout = letters.cast<String>();
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
    initializeGame();
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
    await prefs.setStringList('random_guesses', guesses);
    await prefs.setString('random_currentGuess', currentGuess);
    if (answer != null) await prefs.setString('random_answer', answer!);
    await prefs.setInt('random_elapsed', elapsed.inSeconds);
    if (startTime != null) {
      await prefs.setInt('random_startTime', startTime!.millisecondsSinceEpoch);
    }
    await prefs.setBool('random_gameOver', gameOver);
    await prefs.setString('random_resultMessage', resultMessage ?? '');
  }

  Future<void> restoreGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGuesses = prefs.getStringList('random_guesses');
    final savedCurrentGuess = prefs.getString('random_currentGuess');
    final savedAnswer = prefs.getString('random_answer');
    final savedElapsed = prefs.getInt('random_elapsed');
    final savedStartTime = prefs.getInt('random_startTime');
    final savedGameOver = prefs.getBool('random_gameOver');
    final savedResultMessage = prefs.getString('random_resultMessage');

    if (savedGuesses == null || savedAnswer == null) {
      await initializeGame();
      return;
    }

    final lang = await getConfig("game_lang") ?? "en";
    final pack = await readLanguagePack(lang);
    final letters = pack['letters'] as List<dynamic>;

    guesses = savedGuesses;
    currentGuess = savedCurrentGuess ?? '';
    answer = savedAnswer;
    keyboardLayout = letters.cast<String>();
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
  final RandomWordleController controller;

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
    widget.controller.disposeController();
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
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: c.handleKeyEvent,
        child: GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: Column(
            children: [
              Expanded(
                child: buildGame(
                  guesses: c.guesses,
                  currentGuess: c.currentGuess,
                  answer: c.answer,
                  letterStatuses: c.letterStatuses,
                  keyboardLayout: c.keyboardLayout,
                  onLetterTap: c.gameOver ? (_) {} : c.onLetterTap,
                  onEnterTap: c.gameOver ? () {} : c.onEnterTap,
                  onBackspaceTap: c.gameOver ? () {} : c.onBackspaceTap,
                  elapsed: c.elapsed,
                  onNewGame: c.restartGame,
                  context: context,
                  mode: GameMode.random,
                  gameOver: c.gameOver,
                ),
              ),
              if (c.resultMessage != null)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    c.resultMessage!,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNavigationBar(
        context,
        currentIndex: 0,
      ),
    );
  }
}

class RandomPage extends StatelessWidget {
  const RandomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WordleGameView(
      title: "Random Wordle",
      controller: RandomWordleController(),
    );
  }
}