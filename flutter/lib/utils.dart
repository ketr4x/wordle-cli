import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:crypto/crypto.dart';
import 'online_storage.dart';

enum GameMode { random, daily, ranked }

extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return substring(0, 1).toUpperCase() + substring(1);
  }

  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }
}

void showErrorToast(String message, {bool long = false}) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: long ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
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

Future<String?> _getServerUrl() async {
  final s = await getConfig('server_url');
  if (s == null) return null;
  final trimmed = s.trim();
  if (trimmed.isEmpty) return null;
  return trimmed;
}

Future<void> ensureDefaultServerUrl() async {
  final current = await getConfig('server_url');
  if (current == null) {
    await setConfig('server_url', 'https://wordle.ketrax.ovh');
  }
}

Future<List<String>> getLanguagePacks([bool online = false]) async {
  if (online) {
    final serverUrl = await _getServerUrl();
    if (serverUrl == null) {
      return [];
    }
    final url = '$serverUrl/online/languages';
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 7));
      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.startsWith('[')) {
          final data = json.decode(body);
          if (data is List) {
            return data.map((e) => e.toString()).toList();
          }
          return [];
        } else {
          final parts = body.split(" ").where((s) => s.isNotEmpty).toList();
          return parts;
        }
      }
      return [];
    } catch (e) {
      return await listFiles(true);
    }
  } else {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final files = manifestMap.keys
          .where((k) => k.startsWith('assets/') && k.endsWith('.json'))
          .toList();
      return files.map((f) => f.split('/').last.replaceAll('.json', '')).toList();
    } catch (e) {
      return listFiles();
    }
  }
}

String _extractSha256(String raw) {
  final t = raw.trim().replaceAll(RegExp(r'\s+'), '');
  final match = RegExp(r'([A-Fa-f0-9]{64})').firstMatch(t);
  if (match != null) return match.group(1)!.toLowerCase();
  return t.toLowerCase();
}

Future<String> checkOnlineLanguagePack(String languageCode) async {
  try {
    final serverUrl = await _getServerUrl();
    if (serverUrl == null) {
      return "Server URL not configured";
    }

    final url = '$serverUrl/online/languages/checksum?language=$languageCode';
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 7));

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return "Language invalid";
      }
      return "Error";
    }

    final serverChecksum = _extractSha256(response.body);

    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(serverChecksum)) {
      return "Server returned invalid checksum format";
    }

    final exists = await fileExists(languageCode, true);
    if (!exists) {
      return "Local file missing";
    }
    final content = await readFile(languageCode, true);
    if (content == null) return "Local file missing";
    final localChecksum = sha256.convert(utf8.encode(content)).toString();
    if (localChecksum == serverChecksum) {
      return "Local language file correct";
    }

    return "Local language file invalid (expected $serverChecksum, got $localChecksum)";
  } catch (e) {
    return "Error: $e";
  }
}

Future<Map<String, dynamic>> readLanguagePack(String languageCode, [bool online = false]) async {
  try {
    final String response = await rootBundle.loadString('assets/${online ? 'online/' : ''}$languageCode.json');
    return jsonDecode(response);
  } catch (e) {
    if (online) {
      final content = await readFile(languageCode, true);
      if (content != null) {
        return jsonDecode(content);
      }
      throw Exception('Language pack not found: $languageCode');
    } else {
      if (kIsWeb) {
        throw Exception('Language pack not found: $languageCode');
      }
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}$languageCode.json');
      if (await file.exists()) {
        final contents = await file.readAsString();
        return jsonDecode(contents);
      } else {
        throw Exception('Language pack not found: $languageCode');
      }
    }
  }
}

Future<Map<String, dynamic>> readOnlineLanguagePack(String languageCode) async {
  try {
    final serverUrl = await _getServerUrl();
    if (serverUrl == null) {
      return {'error': 'Server URL is not set up.'};
    }

    final exists = await fileExists(languageCode, true);
    if (!exists) {
      return {'error': 'File does not exist.'};
    }
    final content = await readFile(languageCode, true);
    if (content == null) return {'error': 'File does not exist.'};
    final localChecksum = sha256.convert(utf8.encode(content)).toString();

    final url2 = '$serverUrl/online/languages/checksum?language=$languageCode';
    final response2 = await http.get(Uri.parse(url2)).timeout(const Duration(seconds: 7));

    if (response2.statusCode != 200) {
      return {'error': 'Server did not respond correctly.'};
    }

    final serverChecksum = _extractSha256(response2.body);
    if (localChecksum == serverChecksum) {
      return jsonDecode(content);
    }
    return {'error': 'Error'};
  } catch (e) {
    return {'error': 'Error'};
  }
}

Future<String> downloadOnlineLanguagePack(String languageCode) async {
  try {
    final serverUrl = await _getServerUrl();
    if (serverUrl == null) {
      return "Server URL not configured";
    }

    final url = '$serverUrl/online/languages/download?language=$languageCode';
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return "Language invalid";
      }
      return "Download error";
    }

    await writeFile(languageCode, response.body, true);
    final localChecksum = sha256.convert(utf8.encode(response.body)).toString();

    final url2 = '$serverUrl/online/languages/checksum?language=$languageCode';
    final response2 = await http.get(Uri.parse(url2)).timeout(const Duration(seconds: 7));

    if (response2.statusCode != 200) {
      return "Downloaded - checksum check failed: server responded ${response2.statusCode}";
    }

    final serverChecksum = _extractSha256(response2.body);
    if (localChecksum == serverChecksum) {
      return "Downloaded - file OK";
    }

    return "Downloaded - checksum mismatch (expected $serverChecksum, got $localChecksum)";
  } catch (e) {
    return "Download error: $e";
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
    final newState = await checkConnectionState(null);
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

class LanguageStateProvider extends ChangeNotifier {
  String _status = 'error';
  Timer? _timer;
  String get status => _status;

  LanguageStateProvider() {
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkStatus();
    });
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final data = await checkLanguagesForServer();
    final newStatus = data['status'] as String? ?? 'error';
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  Future<void> forceCheck() async {
    await _checkStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

Future<int> createAccount(String serverUrl, String user, String auth) async {
  final url = '$serverUrl/online/create_user?user=$user&auth=$auth';
  final response = await http.get(Uri.parse(url));
  return response.statusCode;
}

Future<void> createAccountUI(String serverUrl, String user, String auth) async {
  var account = await createAccount(serverUrl, user, auth);
  if (account == 200) {
    Fluttertoast.showToast(
      msg: "Account created successfully.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  } else {
    Fluttertoast.showToast(
      msg: "Failed to create account. Status code: $account",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}

Future<Map<String, dynamic>> checkLanguagesForServer() async {
  final serverLanguages = await getLanguagePacks(true);
  if (serverLanguages.isEmpty) {
    return {
      'status': 'no_server_languages',
      'serverLanguages': serverLanguages,
    };
  }

  List<String> problematic = [];
  Map<String, String> problemsDetails = {};
  for (var lang in serverLanguages) {
    final status = await checkOnlineLanguagePack(lang);
    if (status != "Local language file correct") {
      problematic.add(lang);
      problemsDetails[lang] = status;
    }
  }

  return {
    'status': problematic.isEmpty ? 'all_ok' : 'some_problem',
    'problematic': problematic,
    'details': problemsDetails,
    'serverLanguages': serverLanguages,
  };
}

AppBar buildAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    title: Text(title),
    actions: [
      Consumer3<ConnectionStateProvider, AccountStateProvider, LanguageStateProvider>(
        builder: (context, connProvider, accProvider, langProvider, child) {
          final langStatus = langProvider.status;
          IconData iconData;
          Color iconColor;

          if (connProvider.connectionState == HttpStatus.ok &&
              accProvider.connectionState == HttpStatus.ok &&
              langStatus == 'all_ok') {
            iconData = Icons.cloud_done;
            iconColor = Colors.green;
          } else if (connProvider.connectionState == HttpStatus.ok &&
              accProvider.connectionState == HttpStatus.ok &&
              langStatus == 'some_problem') {
            iconData = Icons.file_download_off;
            iconColor = Colors.orange;
          } else if (connProvider.connectionState == HttpStatus.ok &&
              accProvider.connectionState == HttpStatus.notFound) {
            iconData = Icons.manage_accounts;
            iconColor = Colors.orange;
          } else if (connProvider.connectionState == HttpStatus.ok &&
              accProvider.connectionState == HttpStatus.unauthorized) {
            iconData = Icons.login;
            iconColor = Colors.orange;
          } else {
            iconData = Icons.cloud_off;
            iconColor = Colors.red;
          }

          return IconButton(
            icon: Icon(iconData, color: iconColor),
            onPressed: () async {
              try {
                await Future.wait([
                  connProvider.forceCheck(),
                  accProvider.forceCheck(),
                  langProvider.forceCheck()
                ]);
              } catch (_) {}
              if (context.mounted) {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ConnectivityPage())
                );
              }
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
  List<List<LetterStatus>>? formattedGuesses,
}) {
  String formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  bool isNewDay = true;
  DateTime? startTime;
  if (mode == GameMode.daily && elapsed != null && elapsed > Duration.zero) {
    final now = DateTime.now();
    startTime = now.subtract(elapsed);
    isNewDay = now.day != startTime.day ||
               now.month != startTime.month ||
               now.year != startTime.year;
  } else if (mode == GameMode.daily) {
    startTime = DateTime.now();
    isNewDay = true;
  }

  return Padding(
    padding: const EdgeInsets.all(8),
    child: SingleChildScrollView(
      child: Column(
        children: [
          if (mode == GameMode.daily)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Wordle for ${startTime?.toLocal().toIso8601String().split('T').first}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary
                )
              ),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(6, (index) {
              if (index < guesses.length) {
                final statuses = (formattedGuesses != null && index < formattedGuesses.length)
                  ? formattedGuesses[index]
                  : (answer != null) ? checkGuess(guesses[index], answer) : null;
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
    List<Map<String, dynamic>> parseList(String key) {
      final raw = json[key] as List<dynamic>? ?? [];
      return raw.map((e) {
        if (e is Map<String, dynamic>) return e;
        if (e is Map) return Map<String, dynamic>.from(e);
        return <String, dynamic>{};
      }).toList();
    }

    return LeaderboardData(
      topAvgTime: parseList('top_avg_time'),
      topMatches: parseList('top_matches'),
      topPoints: parseList('top_points'),
      topWinrate: parseList('top_winrate'),
      userPosition: Map<String, dynamic>.from(json['user_position'] ?? {}),
    );
  }
}

Future<int> checkConnectionState(String? serverUrl) async {
  try {
    serverUrl ??= await _getServerUrl();
    if (serverUrl == null) {
      return HttpStatus.notFound;
    }

    final url = '$serverUrl/server_check';
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 7));

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
    final serverUrl = await _getServerUrl();
    if (serverUrl == null) {
      return HttpStatus.notFound;
    }

    final url = '$serverUrl/online/auth_check?user=${await getConfig("username")}&auth=${await getConfig("password")}';
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 7));

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
    final serverUrl = await _getServerUrl();
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