import 'package:universal_html/html.dart' as html;
import 'dart:async';

Future<List<String>> listFiles([bool online = false]) async {
  final keys = html.window.localStorage.keys;
  final prefix = online ? 'online_' : '';
  final out = <String>[];
  for (final k in keys) {
    if (k.startsWith(prefix) && k.endsWith('.json')) {
      final name = k.substring(prefix.length, k.length - 5);
      out.add(name);
    }
  }
  return out;
}

Future<void> writeFile(String name, String content, [bool online = false]) async {
  final key = '${online ? 'online_' : ''}$name.json';
  html.window.localStorage[key] = content;
}

Future<bool> fileExists(String name, [bool online = false]) async {
  final key = '${online ? 'online_' : ''}$name.json';
  return html.window.localStorage.containsKey(key);
}

Future<String?> readFile(String name, [bool online = false]) async {
  final key = '${online ? 'online_' : ''}$name.json';
  return html.window.localStorage[key];
}