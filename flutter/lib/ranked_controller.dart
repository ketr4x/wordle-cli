import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'utils.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RankedWordleController extends ChangeNotifier with WidgetsBindingObserver {
  String? answer;
  List<String> guesses = [];
  List<List<LetterStatus>> formattedGuesses = [];
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
  int guessNumber = 0;
  int gameStatus = 1;
  int gameTime = 0;
  bool loading = false;
  bool _initialized = false;

  static RankedWordleController? _instance;

  factory RankedWordleController() {
    _instance ??= RankedWordleController._internal();
    return _instance!;
  }

  RankedWordleController._internal() {
    ticker = Ticker(_onTick);
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> ensureInitialized() async {
    if (!_initialized) {
      await initializeGame();
      _initialized = true;
    }
  }

  void disposeController() {
    WidgetsBinding.instance.removeObserver(this);
    ticker.stop();
    ticker.dispose();
    _instance = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      isActive = false;
      ticker.stop();
    } else if (state == AppLifecycleState.resumed) {
      isActive = true;
      if (shouldTick && !gameOver && !ticker.isActive) {
        ticker.start();
      }
    }
  }

  Future<void> initializeGame() async {
    loading = true;
    notifyListeners();

    final serverUrl = await getConfig('server_url');
    final user = await getConfig('username');
    final auth = await getConfig('password');
    final lang = await getConfig('game_lang') ?? "en";
    final pack = await readLanguagePack(lang, true);
    final letters = pack['letters'] as List<dynamic>;
    keyboardLayout = letters.cast<String>();

    try {
      final url = '$serverUrl/online/start?user=$user&auth=$auth&language=$lang';
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) {
        errorMessage = "Invalid details. Please try again in a minute.";
        loading = false;
        notifyListeners();
        return;
      }
      guesses.clear();
      formattedGuesses.clear();
      currentGuess = '';
      letterStatuses.clear();
      gameOver = false;
      resultMessage = null;
      errorMessage = null;
      startTime = DateTime.now();
      elapsed = Duration.zero;
      shouldTick = true;
      guessNumber = 0;
      gameStatus = 1;
      gameTime = 0;
      answer = null;
      ticker.stop();
      ticker.start();
      loading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = "Failed to start game: $e";
      loading = false;
      notifyListeners();
    }
  }

  void updateLetterStatuses() {
    if (formattedGuesses.isEmpty) return;
    letterStatuses.clear();
    for (int g = 0; g < guesses.length; g++) {
      final guess = guesses[g];
      final statuses = formattedGuesses[g];
      for (int i = 0; i < guess.length && i < statuses.length; i++) {
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
    if (gameOver || currentGuess.length >= 5 || loading) return;
    currentGuess += letter.toLowerCase();
    errorMessage = null;
    notifyListeners();
  }

  void onBackspaceTap() {
    if (gameOver || currentGuess.isEmpty || loading) return;
    currentGuess = currentGuess.substring(0, currentGuess.length - 1);
    errorMessage = null;
    notifyListeners();
  }

  Future<void> onEnterTap() async {
    if (gameOver || currentGuess.length != 5 || loading) {
      if (currentGuess.length != 5) {
        errorMessage = 'Word must be 5 letters long';
        showErrorToast('Word must be 5 letters long');
        notifyListeners();
      }
      return;
    }
    loading = true;
    notifyListeners();

    final serverUrl = await getConfig('server_url');
    final user = await getConfig('username');
    final auth = await getConfig('password');
    final lang = await getConfig('game_lang') ?? "en";

    final pack = await readLanguagePack(lang, true);
    final answers = pack['solutions'] as List<dynamic>;
    final guessesList = pack['wordlist'] as List<dynamic>;
    final allWords = [...answers, ...guessesList];
    if (!allWords.contains(currentGuess.toLowerCase())) {
      currentGuess = '';
      errorMessage = 'Not a valid word';
      showErrorToast('Not a valid word');
      loading = false;
      notifyListeners();
      return;
    }

    try {
      final url = '$serverUrl/online/guess?user=$user&auth=$auth&guess=$currentGuess';
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body) as Map<String, dynamic>;

        final rawGuesses = (decoded['guesses'] as List<dynamic>?) ?? <dynamic>[];
        final normalizedGuesses = rawGuesses
            .map((g) => (g?.toString() ?? '').trim().toLowerCase())
            .where((s) => s.isNotEmpty)
            .toList();

        final rawFormatted = (decoded['formatted_guesses'] as List<dynamic>?) ?? <dynamic>[];
        final serverFormatted = rawFormatted
            .map((r) => List<dynamic>.from(r as List<dynamic>))
            .toList();

        if (kDebugMode) {
          print('Server guesses: $normalizedGuesses');
          print('Server formatted: $serverFormatted');
        }

        guesses = normalizedGuesses;
        formattedGuesses = serverFormatted.map((row) =>
            row.map((v) {
              final intVal = (v as num).toInt();
              return intVal == 2
                  ? LetterStatus.correct
                  : intVal == 1
                  ? LetterStatus.present
                  : LetterStatus.absent;
            }).toList()
        ).toList();

        guessNumber = (decoded['guess_number'] as num).toInt();
        gameStatus = (decoded['game_status'] as num).toInt();
        gameTime = (decoded['time'] as num).toInt();
        currentGuess = '';

        updateLetterStatuses();

        if (gameStatus != 1) {
          gameOver = true;
          ticker.stop();
          shouldTick = false;
          final wordResp = await http.get(Uri.parse('$serverUrl/online/word?user=$user&auth=$auth'));
          answer = wordResp.statusCode == 200 ? wordResp.body.trim() : null;
          resultMessage = (gameStatus == 2)
              ? 'Congratulations! You won in $guessNumber guesses!\nTime: $gameTime s'
              : 'You lost! The word was: ${answer ?? "?"}';
        }
      } else {
        errorMessage = 'Error: ${resp.body}';
        if (guessNumber >= 6) gameOver = true;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = "Failed to send guess: $e";
      notifyListeners();
    }
    loading = false;
    notifyListeners();
  }

  void restartGame() {
    _initialized = false;
    initializeGame();
  }

  void _onTick(Duration elapsedTick) {
    if (shouldTick && !gameOver && startTime != null && isActive) {
      elapsed = DateTime.now().difference(startTime!);
      notifyListeners();
    }
  }

  void handleKeyEvent(KeyEvent event) {
    if (!kIsWeb || gameOver || loading) return;
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
}