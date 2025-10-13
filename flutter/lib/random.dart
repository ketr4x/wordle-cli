import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'utils.dart';
import 'daily.dart';

class RandomPage extends StatefulWidget {
  const RandomPage({super.key, required this.title});
  final String title;

  @override
  State<RandomPage> createState() => _RandomPageState();
}

class _RandomPageState extends State<RandomPage> with WidgetsBindingObserver {
  final int _selectedIndex = 0;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Ticker(_onTick);
    _initializeGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _ticker.stop();
    } else if (state == AppLifecycleState.resumed && !gameOver) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (!gameOver) {
      setState(() {
        _elapsed = elapsed;
      });
    }
  }

  Future<void> _initializeGame() async {
    final lang = await getConfig("game_lang") ?? "en";
    final pack = await readLanguagePack(lang);
    final letters = pack['letters'] as List<dynamic>;

    final answerWord = await getRandomAnswer();
    setState(() {
      answer = answerWord;
      keyboardLayout = letters.cast<String>();
      guesses.clear();
      currentGuess = '';
      letterStatuses.clear();
      gameOver = false;
      resultMessage = null;
      errorMessage = null;
      _startTime = DateTime.now();
      _elapsed = Duration.zero;
      _ticker.stop();
      _ticker.start();
    });
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
    });
  }

  void _onBackspaceTap() {
    if (gameOver || currentGuess.isEmpty) return;
    setState(() {
      currentGuess = currentGuess.substring(0, currentGuess.length - 1);
      errorMessage = null;
    });
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
        resultMessage = guesses.last.toLowerCase() == answer!.toLowerCase()
          ? 'You win!'
          : 'You lose! Answer: ${answer!}';
      }
    });
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    _ticker.stop();

    Widget page;
    switch (index) {
      case 0:
        page = RandomPage(title: widget.title);
        break;
      case 1:
        page = DailyPage(title: widget.title);
        break;
      case 2:
      case 3:
      case 4:
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _restartGame() {
    _initializeGame();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, "Random Wordle"),
      body: Column(
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
          if (gameOver)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton(
                onPressed: _restartGame,
                child: const Text('Play Again'),
              ),
            ),
        ],
      ),
      bottomNavigationBar: buildBottomNavigationBar(
        context,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}