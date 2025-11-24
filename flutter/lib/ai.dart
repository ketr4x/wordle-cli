import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils.dart';
import 'package:dart_openai/dart_openai.dart';
import 'settings.dart';

class AIWordleController extends ChangeNotifier with WidgetsBindingObserver {
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

  AIWordleController() {
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
    final lang = await getConfig("ai_game_lang") ?? "English";
    errorMessage = null;
    guesses.clear();
    currentGuess = '';
    letterStatuses.clear();
    gameOver = false;
    resultMessage = null;
    startTime = null;
    elapsed = Duration.zero;
    shouldTick = false;
    ticker.stop();
    OpenAI.baseUrl = await getConfig("ai_api_url") ?? OpenAI.baseUrl;
    final apiKey = await getConfig("ai_api_key");
    if (apiKey == null) {
      errorMessage = 'Please set up the API key';
      showErrorToast('Please set up the API key');
      isActive = false;
      notifyListeners();
    } else {
      OpenAI.apiKey = apiKey;
    }
    final model = await getConfig("ai_api_model");
    if (model!.isEmpty) {
      errorMessage = 'Please choose the AI model';
      showErrorToast('Please choose the AI model');
      isActive = false;
      notifyListeners();
    }
    try {
      final aiRequest = await OpenAI.instance.chat.create(
        model: model,
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text('You are a wordle game provider.')
            ]
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                '''
                Provide a single 5-character $lang word suitable as an answer for a Wordle-style game.
                Provide a row list for keyboard for $lang language.
                Reply with a JSON object only, no extra text. Example format for English:
                {"word":"apple","rows":[["Q","W","E","R","T","Y","U","I","O","P"],["A","S","D","F","G","H","J","K","L"],["ENTER","Z","X","C","V","B","N","M","BACKSPACE"]]}
                Return the JSON object exactly as shown (word in lowercase).
                Do not use tags like ```json.
                '''
              )
            ]
          )
        ],
      );
      final aiRequestRaw = aiRequest.choices[0].message.content?[0].text as String;
      final aiRequestDecoded = jsonDecode(aiRequestRaw);
      keyboardRows = (aiRequestDecoded['rows'] as List<dynamic>? ?? [])
        .map<List<String>>((row) {
          if (row is List) {
            return row.map((e) => e?.toString() ?? '').toList();
          }
          return <String>[];
        }).toList();
      answer = aiRequestDecoded['word'] as String;
    } catch (e) {
      errorMessage = e.toString();
      keyboardRows = [];
      answer = '';
    }
    notifyListeners();
    saveGameState();
  }

  Future<bool> isValidAIWord(String word) async {
    final lang = await getConfig("ai_game_lang") ?? "English";
    OpenAI.baseUrl = await getConfig("ai_api_url") ?? OpenAI.baseUrl;
    final apiKey = await getConfig("ai_api_key");
    OpenAI.apiKey = apiKey!;
    final model = await getConfig("ai_api_model");

    final aiRequest = await OpenAI.instance.chat.create(
      model: model!,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
                'You are a wordle game provider.'
            )
          ]
        ),
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              '''
              Check if $word is a correct word in $lang language.
              Reply with a JSON object only, no extra text. Example format:
              {"correct": true}
              Return the JSON object exactly as shown (false or true).
              Do not use tags like ```json.
              '''
            )
          ]
        )
      ],
    );
    final aiRequestRaw = aiRequest.choices[0].message.content?[0].text as String;
    final aiRequestDecoded = jsonDecode(aiRequestRaw);
    return aiRequestDecoded['correct'] == true;
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

    bool isValid = await isValidAIWord(currentGuess);
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
    await prefs.setStringList('ai_guesses', guesses);
    await prefs.setString('ai_currentGuess', currentGuess);
    if (answer != null) await prefs.setString('ai_answer', answer!);
    await prefs.setInt('ai_elapsed', elapsed.inSeconds);
    if (startTime != null) {
      await prefs.setInt('ai_startTime', startTime!.millisecondsSinceEpoch);
    }
    await prefs.setBool('ai_gameOver', gameOver);
    await prefs.setString('ai_resultMessage', resultMessage ?? '');
    await prefs.setString('ai_rows', jsonEncode(keyboardRows));
  }

  Future<void> restoreGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGuesses = prefs.getStringList('ai_guesses');
    final savedCurrentGuess = prefs.getString('ai_currentGuess');
    final savedAnswer = prefs.getString('ai_answer');
    final savedElapsed = prefs.getInt('ai_elapsed');
    final savedStartTime = prefs.getInt('ai_startTime');
    final savedGameOver = prefs.getBool('ai_gameOver');
    final savedResultMessage = prefs.getString('ai_resultMessage');
    final savedRows = prefs.getString('ai_rows');

    if (savedGuesses == null || savedAnswer == null) {
      await initializeGame();
      return;
    }

    keyboardRows = (savedRows != null ? jsonDecode(savedRows) : [])
        .map<List<String>>((row) => (row as List<dynamic>).map((e) => e.toString()).toList())
        .toList();
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
  final AIWordleController controller;

  const WordleGameView({super.key, required this.title, required this.controller});

  @override
  State<WordleGameView> createState() => _WordleGameViewState();
}

class _WordleGameViewState extends State<WordleGameView> {
  final FocusNode _focusNode = FocusNode();
  String lastErrorPopup = '';

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
    final child = GestureDetector(
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
              onNewGame: c.restartGame,
              context: context,
              mode: GameMode.random,
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
          if (c.errorMessage != null && lastErrorPopup != c.errorMessage) ...[
            Builder(
              builder: (context) {
                final capturedError = c.errorMessage;
                if (capturedError == 'Please set up the API key' || capturedError == 'Please choose the AI model') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!context.mounted) return;
                    lastErrorPopup = c.errorMessage!;
                    showAdaptiveDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Invalid API info'),
                        content: Text(
                          c.errorMessage == 'Please set up the API key'
                          ? 'The API key is invalid. Check it or change the API url.'
                          : 'Please choose a different AI model.'
                        ),
                        actions: [
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsPage())
                              );
                            },
                            child: const Text('Settings')
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK')
                          )
                        ],
                      )
                    );
                  });
                }
                return const SizedBox.shrink();
              }
            )
          ],
          if (c.resultMessage != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                c.resultMessage!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
        ],
      ),
    );
    return Scaffold(
      appBar: buildAppBar(context, widget.title),
      drawer: buildDrawer(context),
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: c.handleKeyEvent,
        child: child,
      ),
      bottomNavigationBar: buildBottomNavigationBar(
        context,
        currentIndex: 1,
      ),
    );
  }
}

class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  late final AIWordleController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AIWordleController();
  }

  @override
  void dispose() {
    _controller.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WordleGameView(
        title: "AI Wordle",
        controller: _controller
    );
  }
}