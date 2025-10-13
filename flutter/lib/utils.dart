import 'package:flutter/material.dart';
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
  final dir = await getApplicationDocumentsDirectory();
  final files = dir.listSync();
  return files
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''))
      .toList();
}

Future<Map<String, dynamic>> readLanguagePack(String languageCode) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$languageCode.json');
  if (await file.exists()) {
    final contents = await file.readAsString();
    return jsonDecode(contents);
  } else {
    throw Exception('Language pack not found');
  }
}
Future<String> getRandomAnswer({int length = 5, bool daily = false}) async {
  var lang = await getConfig("game_lang");
  var pack = await readLanguagePack(lang as String);
  var answers = pack['answers'] as List<String>;
  if (daily) {
    var startDate = DateTime(2022, 6, 19);
    var today = DateTime.now();
    var daysDiff = today.difference(startDate).inDays;
    return answers[daysDiff % answers.length];
  }
  return answers[Random().nextInt(answers.length)];
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
  final double boxSize;
  final TextStyle textStyle;
  final Color boxColor;
  final Color borderColor;

  const WordleLetterBoxes({
    super.key,
    required this.letters,
    this.boxSize = 48,
    this.textStyle = const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    this.boxColor = Colors.white,
    this.borderColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        String letter = index < letters.length ? letters[index] : '';
        return Container(
          width: boxSize,
          height: boxSize,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: boxColor,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            letter.toUpperCase(),
            style: textStyle,
          ),
        );
      }),
    );
  }
}