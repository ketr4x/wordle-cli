import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wordle/universal_game.dart';
import 'daily.dart';
import 'leaderboard.dart';
import 'random.dart';
import 'ranked.dart';
import 'settings.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:provider/provider.dart';
import 'statistics.dart';
import 'connectivity.dart';

void showErrorToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: Colors.red,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

void showDailyLimitToast() {
  Fluttertoast.showToast(
    msg: "You can play tomorrow.",
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: Colors.orange,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

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

class ConnectionStateProvider extends ChangeNotifier {
  int _connectionState = HttpStatus.internalServerError;
  Timer? _connectionTimer;

  int get connectionState => _connectionState;

  ConnectionStateProvider() {
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    _connectionTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkConnection();
    });
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final newState = await checkConnectionState();
    if (_connectionState != newState) {
      _connectionState = newState;
      notifyListeners();
    }
  }

  Future<void> forceCheck() async {
    await _checkConnection();
  }

  @override
  void dispose() {
    _connectionTimer?.cancel();
    super.dispose();
  }
}

class AccountStateProvider extends ChangeNotifier {
  int _accountState = HttpStatus.internalServerError;
  Timer? _accountTimer;

  int get connectionState => _accountState;

  AccountStateProvider() {
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    _accountTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkAccount();
    });
    _checkAccount();
  }

  Future<void> _checkAccount() async {
    final newState = await checkAccountState();
    if (_accountState != newState) {
      _accountState = newState;
      notifyListeners();
    }
  }

  Future<void> forceCheck() async {
    await _checkAccount();
  }

  @override
  void dispose() {
    _accountTimer?.cancel();
    super.dispose();
  }
}

AppBar buildAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    title: Text(title),
    actions: [
      Consumer2<ConnectionStateProvider, AccountStateProvider>(
        builder: (context, connProvider, accProvider, child) {
          return IconButton(
            icon: Icon(
              connProvider.connectionState == HttpStatus.ok &&
                      accProvider.connectionState == HttpStatus.ok
                  ? Icons.cloud_done
                  : connProvider.connectionState == HttpStatus.ok &&
                  accProvider.connectionState == HttpStatus.notFound
                  ? Icons.manage_accounts
                  : connProvider.connectionState == HttpStatus.ok &&
                  accProvider.connectionState == HttpStatus.unauthorized
                  ? Icons.login
                  : Icons.cloud_off,
              color: connProvider.connectionState == HttpStatus.ok &&
                      accProvider.connectionState == HttpStatus.ok
                  ? Colors.green
                  : connProvider.connectionState == HttpStatus.ok &&
                  accProvider.connectionState != HttpStatus.ok
                  ? Colors.orange
                  : Colors.red,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConnectivityPage()),
              );
            },
          );
        },
      ),
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
      required widget,
    }
    ) {
  return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) {
        Widget page;
        switch (index) {
          case 0:
            page = RandomPage();
            break;
          case 1:
            page = DailyPage();
            break;
          case 2:
            page = RankedPage();
            break;
          case 3:
            page = LeaderboardPage();
            break;
          case 4:
            page = StatsPage();
            break;
          default:
            return;
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
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
    this.boxSize = 54,
    this.textStyle = const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
  });

  Color _getBoxColor(LetterStatus? status, BuildContext context) {
    if (status == null) {
      return Theme.of(context).colorScheme.surface;
    }
    switch (status) {
      case LetterStatus.correct:
        return const Color(0xFF6AAA64);
      case LetterStatus.present:
        return const Color(0xFFC9B458);
      case LetterStatus.absent:
        return const Color(0xFF787C7E);
    }
  }

  Color _getTextColor(LetterStatus? status, BuildContext context) {
    if (status == null) {
      return Theme.of(context).colorScheme.onSurface;
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

        return Flexible(
          child: Container(
            width: boxSize,
            height: boxSize,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: _getBoxColor(status, context),
              border: Border.all(
                color: status == null
                  ? Theme.of(context).colorScheme.outline
                  : Colors.transparent,
                width: 2
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              letter.toUpperCase(),
              style: textStyle.copyWith(color: _getTextColor(status, context)),
            ),
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
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
    switch (status) {
      case LetterStatus.correct:
        return const Color(0xFF6AAA64);
      case LetterStatus.present:
        return const Color(0xFFC9B458);
      case LetterStatus.absent:
        return const Color(0xFF787C7E);
    }
  }

  Color _getKeyTextColor(String letter, BuildContext context) {
    final status = letterStatuses[letter.toLowerCase()];
    if (status == null) {
      return Theme.of(context).colorScheme.onSurface;
    }
    return Colors.white;
  }

  Widget _buildKey(String key, BuildContext context) {
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
              ? Theme.of(context).colorScheme.onPrimary
              : _getKeyTextColor(key, context),
            padding: const EdgeInsets.all(0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            elevation: 0,
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
    if (keyboardLayout.length < 26) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: const Center(
          child: Text('Loading keyboard...'),
        ),
      );
    }

    final List<List<String>> rows = [
      keyboardLayout.sublist(0, 10),
      keyboardLayout.sublist(10, 19),
      ['ENTER', ...keyboardLayout.sublist(19, 26), 'BACKSPACE'],
    ];

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width < 800 ? double.infinity : 800,
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: rows.map((row) =>
              Row(
                children: row.map((key) => _buildKey(key, context)).toList(),
              )
            ).toList(),
          ),
        ),
      ),
    );
  }
}

Widget buildGame({
  required List<String> guesses,
  required String currentGuess,
  String? answer,
  required Map<String, LetterStatus> letterStatuses,
  required List<String> keyboardLayout,
  required Function(String) onLetterTap,
  required VoidCallback onEnterTap,
  required VoidCallback onBackspaceTap,
  Duration? elapsed,
  VoidCallback? onNewGame,
  required BuildContext context,
  GameMode? mode,
  bool gameOver = false,
}) {
  String formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  bool isNewDay = true;
  if (mode == GameMode.daily && elapsed != null && elapsed > Duration.zero) {
    final now = DateTime.now();
    final startTime = now.subtract(elapsed);
    isNewDay = now.day != startTime.day ||
               now.month != startTime.month ||
               now.year != startTime.year;
  }

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
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: WordleLetterBoxes(
                    letters: guesses[index],
                    statuses: statuses,
                  ),
                );
              } else if (index == guesses.length && currentGuess.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: WordleLetterBoxes(letters: currentGuess),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: const WordleLetterBoxes(letters: ''),
                );
              }
            }),
          ),
        ),
        if (!gameOver)
          WordleKeyboard(
            letterStatuses: letterStatuses,
            keyboardLayout: keyboardLayout,
            onLetterTap: onLetterTap,
            onEnterTap: onEnterTap,
            onBackspaceTap: onBackspaceTap,
          ),
        SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (elapsed != null)
                Text(
                  "Time: ${formatDuration(elapsed)}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: ElevatedButton(
                  onPressed: (mode == GameMode.daily)
                    ? () {
                        if (isNewDay) {
                          if (onNewGame != null) onNewGame();
                        } else {
                          showDailyLimitToast();
                        }
                      }
                    : onNewGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    minimumSize: const Size(0, 36),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('New Game'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class LeaderboardData {
  final List<Map<String, dynamic>> topAvgTime;
  final List<Map<String, dynamic>> topMatches;
  final List<Map<String, dynamic>> topPoints;
  final List<Map<String, dynamic>> topWinrate;
  final Map<String, dynamic> userPosition;

  LeaderboardData({
    required this.topAvgTime,
    required this.topMatches,
    required this.topPoints,
    required this.topWinrate,
    required this.userPosition,
  });

  factory LeaderboardData.fromJson(Map<String, dynamic> json) {
    return LeaderboardData(
      topAvgTime: List<Map<String, dynamic>>.from(json['top_avg_time'] ?? []),
      topMatches: List<Map<String, dynamic>>.from(json['top_matches'] ?? []),
      topPoints: List<Map<String, dynamic>>.from(json['top_points'] ?? []),
      topWinrate: List<Map<String, dynamic>>.from(json['top_winrate'] ?? []),
      userPosition: Map<String, dynamic>.from(json['user_position'] ?? {}),
    );
  }
}

Future<int> checkConnectionState() async {
  try {
    final serverUrl = await getConfig('server_url');
    if (serverUrl == null) {
      return HttpStatus.notFound;
    }

    final url = '$serverUrl/server_check';
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      return HttpStatus.ok;
    } else {
      return HttpStatus.badRequest;
    }
  } catch (e) {
    return HttpStatus.internalServerError;
  }
}

Future<int> checkAccountState() async {
  try {
    final serverUrl = await getConfig('server_url');
    if (serverUrl == null) {
      return HttpStatus.notFound;
    }

    final url = '$serverUrl/online/auth_check?user=${await getConfig("username")}&auth=${await getConfig("password")}';
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      return HttpStatus.ok;
    } else if (response.statusCode == 401) {
      return HttpStatus.notFound;
    } else if (response.statusCode == 403) {
      return HttpStatus.unauthorized;
    } else {
      return HttpStatus.internalServerError;
    }
  } catch (e) {
    return HttpStatus.internalServerError;
  }
}

Future<LeaderboardData?> getLeaderboard(String state, String user, String auth) async {
  try {
    final serverUrl = await getConfig('server_url');
    if (serverUrl == null) {
      throw Exception('Server URL not configured');
    }
    
    final url = '$serverUrl/online/leaderboard?state=$state&user=$user&auth=$auth';
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return LeaderboardData.fromJson(data);
    } else {
      throw Exception('Failed to load leaderboard: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching leaderboard: $e');
  }
}