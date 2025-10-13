import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils.dart';

enum GameMode { random, daily }

class GamePage extends StatefulWidget {
  final String title;
  final GameMode mode;

  const GamePage({super.key, required this.title, required this.mode});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  late final int _selectedIndex;
  String? answer;
  List<String> guesses = [];
  String currentGuess = '';
  Map<String, LetterStatus> letterStatuses = {};
  List<String> keyboardLayout = [];
  bool gameOver = false;
  String? resultMessage;
  String? errorMessage;
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  late final Ticker _ticker;
  final FocusNode _focusNode = FocusNode();
  bool _shouldTick = false;
  bool _isActive = true;

  String get _prefsPrefix => widget.mode == GameMode.daily ? 'daily' : 'random';

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.mode == GameMode.daily ? 1 : 0;
    WidgetsBinding.instance.addObserver(this);
    _ticker = Ticker(_onTick);
    _restoreGameState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _focusNode.dispose();
    _saveGameState();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _isActive = false;
      _ticker.stop();
      _saveGameState();
    } else if (state == AppLifecycleState.resumed) {
      _isActive = true;
      if (_shouldTick && !gameOver && !_ticker.isActive) {
        _ticker.start();
      }
    }
  }

  Future<void> _initializeGame() async {
    final lang = await getConfig("game_lang") ?? "en";
    final pack = await readLanguagePack(lang);
    final letters = pack['letters'] as List<dynamic>;
    final answerWord = await getRandomAnswer(daily: widget.mode == GameMode.daily);

    setState(() {
      answer = answerWord;
      keyboardLayout = letters.cast<String>();
      guesses.clear();
      currentGuess = '';
      letterStatuses.clear();
      gameOver = false;
      resultMessage = null;
      errorMessage = null;
      _startTime = null;
      _elapsed = Duration.zero;
      _shouldTick = false;
      _ticker.stop();
    });
    _saveGameState();
  }

  void _updateLetterStatuses() {
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

  void _onLetterTap(String letter) {
    if (gameOver || currentGuess.length >= 5) return;
    setState(() {
      currentGuess += letter.toLowerCase();
      errorMessage = null;
      if (!_shouldTick) {
        _shouldTick = true;
        _startTime = DateTime.now();
        _elapsed = Duration.zero;
        if (_isActive) _ticker.start();
      } else if (_isActive && !_ticker.isActive) {
        _ticker.start();
      }
    });
    _saveGameState();
  }

  void _onBackspaceTap() {
    if (gameOver || currentGuess.isEmpty) return;
    setState(() {
      currentGuess = currentGuess.substring(0, currentGuess.length - 1);
      errorMessage = null;
    });
    _saveGameState();
  }

  void _onEnterTap() async {
    if (gameOver || answer == null || currentGuess.length != 5) {
      if (currentGuess.length != 5) {
        setState(() {
          errorMessage = 'Word must be 5 letters long';
        });
        showErrorToast('Word must be 5 letters long');
      }
      return;
    }

    bool isValid = await isValidWord(currentGuess);
    if (!isValid) {
      setState(() {
        currentGuess = '';
        errorMessage = 'Not a valid word';
      });
      showErrorToast('Not a valid word');
      _saveGameState();
      return;
    }

    setState(() {
      guesses.add(currentGuess);
      currentGuess = '';
      errorMessage = null;
      _updateLetterStatuses();
      if (guesses.last.toLowerCase() == answer!.toLowerCase() || guesses.length == 6) {
        gameOver = true;
        _ticker.stop();
        _shouldTick = false;
        resultMessage = guesses.last.toLowerCase() == answer!.toLowerCase()
          ? 'You win!'
          : 'You lose! Answer: ${answer!}';
      }
    });
    _saveGameState();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    _ticker.stop();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GamePage(
          title: index == 1 ? "Daily Wordle" : "Random Wordle",
          mode: index == 1 ? GameMode.daily : GameMode.random,
        ),
      ),
    );
  }

  void _restartGame() {
    _initializeGame();
    _saveGameState();
  }

  void _resetGuesses() {
    setState(() {
      guesses.clear();
      currentGuess = '';
      letterStatuses.clear();
      gameOver = false;
      resultMessage = null;
      errorMessage = null;
      _startTime = null;
      _elapsed = Duration.zero;
      _shouldTick = false;
      _ticker.stop();
    });
    _saveGameState();
  }

  void _onTick(Duration elapsed) {
    if (_shouldTick && !gameOver && _startTime != null && _isActive) {
      setState(() {
        _elapsed = DateTime.now().difference(_startTime!);
      });
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (!kIsWeb || gameOver) return;
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.enter) {
        _onEnterTap();
      } else if (key == LogicalKeyboardKey.backspace) {
        _onBackspaceTap();
      } else if (key.keyLabel.length == 1 && RegExp(r'^[a-zA-Z]$').hasMatch(key.keyLabel)) {
        _onLetterTap(key.keyLabel.toLowerCase());
      }
    }
  }

  Future<void> _saveGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${_prefsPrefix}_guesses', guesses);
    await prefs.setString('${_prefsPrefix}_currentGuess', currentGuess);
    if (answer != null) await prefs.setString('${_prefsPrefix}_answer', answer!);
    await prefs.setInt('${_prefsPrefix}_elapsed', _elapsed.inSeconds);
    if (_startTime != null) {
      await prefs.setInt('${_prefsPrefix}_startTime', _startTime!.millisecondsSinceEpoch);
    }
    await prefs.setBool('${_prefsPrefix}_gameOver', gameOver);
    await prefs.setString('${_prefsPrefix}_resultMessage', resultMessage ?? '');
  }

  Future<void> _restoreGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGuesses = prefs.getStringList('${_prefsPrefix}_guesses');
    final savedCurrentGuess = prefs.getString('${_prefsPrefix}_currentGuess');
    final savedAnswer = prefs.getString('${_prefsPrefix}_answer');
    final savedElapsed = prefs.getInt('${_prefsPrefix}_elapsed');
    final savedStartTime = prefs.getInt('${_prefsPrefix}_startTime');
    final savedGameOver = prefs.getBool('${_prefsPrefix}_gameOver');
    final savedResultMessage = prefs.getString('${_prefsPrefix}_resultMessage');

    if (savedGuesses == null || savedAnswer == null) {
      await _initializeGame();
      return;
    }

    final lang = await getConfig("game_lang") ?? "en";
    final pack = await readLanguagePack(lang);
    final letters = pack['letters'] as List<dynamic>;

    setState(() {
      guesses = savedGuesses;
      currentGuess = savedCurrentGuess ?? '';
      answer = savedAnswer;
      keyboardLayout = letters.cast<String>();
      gameOver = savedGameOver ?? false;
      resultMessage = (savedResultMessage?.isEmpty ?? true) ? null : savedResultMessage;
      errorMessage = null;

      if (savedStartTime != null && savedElapsed != null && savedElapsed > 0) {
        _startTime = DateTime.fromMillisecondsSinceEpoch(savedStartTime);
        _elapsed = DateTime.now().difference(_startTime!);
        _shouldTick = true;
      } else {
        _startTime = null;
        _elapsed = Duration.zero;
        _shouldTick = false;
      }

      _updateLetterStatuses();

      _ticker.stop();
      if (_shouldTick && !gameOver) {
        _ticker.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, widget.title),
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: Column(
            children: [
              Expanded(
                child: buildGame(
                  guesses: guesses,
                  currentGuess: currentGuess,
                  answer: answer,
                  letterStatuses: letterStatuses,
                  keyboardLayout: keyboardLayout,
                  onLetterTap: gameOver ? (_) {} : _onLetterTap,
                  onEnterTap: gameOver ? () {} : _onEnterTap,
                  onBackspaceTap: gameOver ? () {} : _onBackspaceTap,
                  elapsed: _elapsed,
                  onNewGame: widget.mode == GameMode.daily ? _resetGuesses : _restartGame,
                  context: context,
                  mode: widget.mode,
                  gameOver: gameOver,
                ),
              ),
              if (resultMessage != null)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    resultMessage!,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNavigationBar(
        context,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}