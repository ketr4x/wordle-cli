import 'package:flutter/material.dart';
import 'utils.dart';
import 'random.dart';

class DailyPage extends StatefulWidget {
  const DailyPage({super.key, required this.title});
  final String title;

  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  final int _selectedIndex = 1;

  String? answer;
  List<String> guesses = [];
  String currentGuess = '';
  Map<String, LetterStatus> letterStatuses = {};
  List<String> keyboardLayout = [];
  bool gameOver = false;
  String? resultMessage;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    final lang = await getConfig("game_lang") ?? "en";
    final pack = await readLanguagePack(lang);
    final letters = pack['letters'] as List<dynamic>;

    final answerWord = await getRandomAnswer(daily: true);
    setState(() {
      answer = answerWord;
      keyboardLayout = letters.cast<String>();
      guesses.clear();
      currentGuess = '';
      letterStatuses.clear();
      gameOver = false;
      resultMessage = null;
      errorMessage = null;
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

        // Priority: correct > present > absent
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
      }
      return;
    }

    // Validate word
    bool isValid = await isValidWord(currentGuess);
    if (!isValid) {
      setState(() {
        errorMessage = 'Not a valid word';
      });
      return;
    }

    setState(() {
      guesses.add(currentGuess);
      currentGuess = '';
      errorMessage = null;

      _updateLetterStatuses();

      if (guesses.last.toLowerCase() == answer!.toLowerCase()) {
        gameOver = true;
        resultMessage = 'You win!';
      } else if (guesses.length == 6) {
        gameOver = true;
        resultMessage = 'You lose! Answer: ${answer!}';
      }
    });
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

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

  void _resetGuesses() {
    setState(() {
      guesses.clear();
      currentGuess = '';
      letterStatuses.clear();
      gameOver = false;
      resultMessage = null;
      errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, widget),
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
            ),
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
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
                onPressed: _resetGuesses,
                child: const Text('Try Again'),
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