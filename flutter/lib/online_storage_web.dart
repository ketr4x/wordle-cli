import 'package:universal_html/html.dart' as html;
import 'dart:async';

Future<List<String>> listOnlineFiles() async {
  final keys = html.window.localStorage.keys;
  final prefix = 'online_';
  final out = <String>[];
  for (final k in keys) {
    if (k.startsWith(prefix) && k.endsWith('.json')) {
      final name = k.substring(prefix.length, k.length - 5);
      out.add(name);
    }
  }
  return out;
}

Future<void> writeOnlineFile(String name, String content) async {
  final key = 'online_$name.json';
  html.window.localStorage[key] = content;
}

Future<bool> onlineFileExists(String name) async {
  final key = 'online_$name.json';
  return html.window.localStorage.containsKey(key);
}

Future<String?> readOnlineFile(String name) async {
  final key = 'online_$name.json';
  return html.window.localStorage[key];
}