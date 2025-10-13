import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'settings.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

Future<void> setConfig(String key, String value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}

Future<String?> getConfig(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}

Future<List<String>> getLanguagePacks() async {
  return ['en'];
}

Future<Map<String, dynamic>> readLanguagePack(String languageCode) async {
  try {
    final String response = await rootBundle.loadString('assets/$languageCode.json');
    return jsonDecode(response);
  } catch (e) {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$languageCode.json');
    if (await file.exists()) {
      final contents = await file.readAsString();
      return jsonDecode(contents);
    } else {
      throw Exception('Language pack not found: $languageCode');
    }
  }
}

Future<String> getRandomAnswer({bool daily = false}) async {
  var lang = await getConfig("game_lang");
  if (lang == null) {
    lang = "en";
    await setConfig("game_lang", lang);
  }

  var pack = await readLanguagePack(lang);
  var answers = pack['solutions'] as List<dynamic>;
  var answersList = answers.cast<String>();

  if (daily) {
    var startDate = DateTime(2025, 10, 7);
    var today = DateTime.now();
    var daysDiff = today.difference(startDate).inDays;
    return answersList[daysDiff % answersList.length];
  }
  return answersList[Random().nextInt(answersList.length)];
}

Future<bool> isValidWord(String word) async {
  try {
    var lang = await getConfig("game_lang");
    if (lang == null) {
      lang = "en";
      await setConfig("game_lang", lang);
    }

    var pack = await readLanguagePack(lang);
    var answers = pack['solutions'] as List<dynamic>;
    var guesses = pack['wordlist'] as List<dynamic>;

    var allWords = [...answers, ...guesses];
    return allWords.contains(word.toLowerCase());
  } catch (e) {
    return false;
  }
}

enum LetterStatus { correct, present, absent }

List<LetterStatus> checkGuess(String guess, String answer) {
  List<LetterStatus> result = List.filled(5, LetterStatus.absent);
  String lowerGuess = guess.toLowerCase();
  String lowerAnswer = answer.toLowerCase();

  for (int i = 0; i < 5; i++) {
    if (lowerGuess[i] == lowerAnswer[i]) {
      result[i] = LetterStatus.correct;
    }
  }

  List<String> remainingAnswer = [];
  for (int i = 0; i < 5; i++) {
    if (result[i] != LetterStatus.correct) {
      remainingAnswer.add(lowerAnswer[i]);
    }
  }

  for (int i = 0; i < 5; i++) {
    if (result[i] == LetterStatus.absent) {
      if (remainingAnswer.contains(lowerGuess[i])) {
        result[i] = LetterStatus.present;
        remainingAnswer.remove(lowerGuess[i]);
      }
    }
  }

  return result;
}

AppBar buildAppBar(BuildContext context, widget) {
  return AppBar(
    backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    title: Text(widget.title),
    actions: [
      IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        },
      ),
    ],
  );
}

BottomNavigationBar buildBottomNavigationBar(
    BuildContext context, {
    required int currentIndex,
    required ValueChanged<int> onTap,
    }
    )
{
  return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.shuffle),
          label: 'Random',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Daily',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.star),
          label: 'Ranked',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.leaderboard),
          label: 'Leaderboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.query_stats),
          label: 'Stats',
        ),
      ]
  );
}

class WordleLetterBoxes extends StatelessWidget {
  final String letters;
  final List<LetterStatus>? statuses;
  final double boxSize;
  final TextStyle textStyle;

  const WordleLetterBoxes({
    super.key,
    required this.letters,
    this.statuses,
    this.boxSize = 48,
    this.textStyle = const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  });

  Color _getBoxColor(LetterStatus? status, BuildContext context) {
    if (status == null) {
      return Theme.of(context).colorScheme.surface;
    }
    switch (status) {
      case LetterStatus.correct:
        return Colors.green;
      case LetterStatus.present:
        return Colors.orange;
      case LetterStatus.absent:
        return Colors.grey;
    }
  }

  Color _getTextColor(LetterStatus? status) {
    if (status == null) {
      return Colors.black;
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        String letter = index < letters.length ? letters[index] : '';
        LetterStatus? status = statuses != null && index < statuses!.length ? statuses![index] : null;

        return Container(
          width: boxSize,
          height: boxSize,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _getBoxColor(status, context),
            border: Border.all(
              color: status == null ? Colors.grey : Colors.transparent,
              width: 2
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            letter.toUpperCase(),
            style: textStyle.copyWith(color: _getTextColor(status)),
          ),
        );
      }),
    );
  }
}

class WordleKeyboard extends StatelessWidget {
  final Map<String, LetterStatus> letterStatuses;
  final Function(String) onLetterTap;
  final VoidCallback onEnterTap;
  final VoidCallback onBackspaceTap;
  final List<String> keyboardLayout;

  const WordleKeyboard({
    super.key,
    required this.letterStatuses,
    required this.onLetterTap,
    required this.onEnterTap,
    required this.onBackspaceTap,
    required this.keyboardLayout,
  });

  Color _getKeyColor(String letter, BuildContext context) {
    final status = letterStatuses[letter.toLowerCase()];
    if (status == null) {
      return Theme.of(context).colorScheme.surface;
    }
    switch (status) {
      case LetterStatus.correct:
        return Colors.green;
      case LetterStatus.present:
        return Colors.orange;
      case LetterStatus.absent:
        return Colors.grey;
    }
  }

  Color _getKeyTextColor(String letter) {
    final status = letterStatuses[letter.toLowerCase()];
    return status == null ? Colors.black : Colors.white;
  }

  Widget _buildKey(String key, BuildContext context, {double? width}) {
    final isSpecial = key == 'ENTER' || key == 'BACKSPACE';
    return Expanded(
      flex: isSpecial ? 3 : 2,
      child: Container(
        height: 48,
        margin: const EdgeInsets.all(2),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSpecial
              ? Theme.of(context).colorScheme.primary
              : _getKeyColor(key, context),
            foregroundColor: isSpecial
              ? Colors.white
              : _getKeyTextColor(key),
            padding: const EdgeInsets.all(0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          onPressed: () {
            if (key == 'ENTER') {
              onEnterTap();
            } else if (key == 'BACKSPACE') {
              onBackspaceTap();
            } else {
              onLetterTap(key);
            }
          },
          child: Text(
            key == 'BACKSPACE' ? '⌫' : key,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Standard QWERTY layout
    final List<List<String>> rows = [
      keyboardLayout.sublist(0, 10), // Q-P
      keyboardLayout.sublist(10, 19), // A-L
      ['ENTER', ...keyboardLayout.sublist(19, 26), 'BACKSPACE'], // Z-M with special keys
    ];

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: rows.map((row) =>
          Row(
            children: row.map((key) => _buildKey(key, context)).toList(),
          )
        ).toList(),
      ),
    );
  }
}

Padding buildGame({
  required List<String> guesses,
  required String currentGuess,
  String? answer,
  required Map<String, LetterStatus> letterStatuses,
  required List<String> keyboardLayout,
  required Function(String) onLetterTap,
  required VoidCallback onEnterTap,
  required VoidCallback onBackspaceTap,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(10, 25, 10, 8),
    child: Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(6, (index) {
              if (index < guesses.length && answer != null) {
                List<LetterStatus> statuses = checkGuess(guesses[index], answer);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: WordleLetterBoxes(
                    letters: guesses[index],
                    statuses: statuses,
                  ),
                );
              } else if (index == guesses.length && currentGuess.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: WordleLetterBoxes(letters: currentGuess),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: const WordleLetterBoxes(letters: ''),
                );
              }
            }),
          ),
        ),
        WordleKeyboard(
          letterStatuses: letterStatuses,
          keyboardLayout: keyboardLayout,
          onLetterTap: onLetterTap,
          onEnterTap: onEnterTap,
          onBackspaceTap: onBackspaceTap,
        ),
      ],
    ),
  );
}