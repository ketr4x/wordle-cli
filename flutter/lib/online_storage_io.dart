import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:path/path.dart' as p;

Future<Directory> _getBaseDir([bool online = false]) async {
  final base = await getApplicationSupportDirectory();
  final dir = online ? Directory(p.join(base.path, 'online')) : Directory(base.path);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

Future<List<String>> listFiles([bool online = false]) async {
  final dir = await _getBaseDir(online);
  final entities = await dir.list().toList();
  return entities
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .map((f) => p.basenameWithoutExtension(f.path))
      .toList();
}

Future<void> writeOnlineFile(String name, String content) async {
  final dir = await _getBaseDir();
  final file = File(p.join(dir.path, '$name.json'));
  await file.writeAsString(content, flush: true);
}

Future<bool> onlineFileExists(String name) async {
  final dir = await _getBaseDir();
  final file = File(p.join(dir.path, '$name.json'));
  return file.exists();
}

Future<String?> readOnlineFile(String name) async {
  final dir = await _getBaseDir();
  final file = File(p.join(dir.path, '$name.json'));
  if (!await file.exists()) return null;
  return await file.readAsString();
}