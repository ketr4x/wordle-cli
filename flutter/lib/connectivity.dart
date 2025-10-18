import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings.dart';
import 'utils.dart';
import 'dart:io';

class ConnectivityPage extends StatefulWidget {
  const ConnectivityPage({super.key});

  @override
  State<ConnectivityPage> createState() => _ConnectivityPageState();
}

class _ConnectivityPageState extends State<ConnectivityPage> {
  String _serverUrl = '';
  String _username = '';
  String _password = '';

  Future<Map<String, dynamic>>? _lastCheckFuture;
  Map<String, dynamic>? _lastCheckResult;
  DateTime? _lastCheckTime;

  void _invalidateLanguageCheckCache() {
    _lastCheckFuture = null;
    _lastCheckResult = null;
    _lastCheckTime = null;
  }

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadPassword();
    _loadServerUrl();
  }

  Future<void> _loadUsername() async {
    final username = await getConfig("username");
    setState(() {
      _username = username ?? '';
    });
  }

  Future<void> _loadPassword() async {
    final password = await getConfig("password");
    setState(() {
      _password = password ?? '';
    });
  }

  Future<void> _loadServerUrl() async {
    final serverUrl = await getConfig("server_url");
    setState(() {
      _serverUrl = serverUrl ?? '';
    });
  }

  Future<Map<String, dynamic>> _checkLanguagesForServer({bool force = false}) async {
    if (!force && _lastCheckResult != null && _lastCheckTime != null) {
      final age = DateTime.now().difference(_lastCheckTime!);
      if (age < const Duration(seconds: 30)) {
        return _lastCheckResult!;
      }
    }

    if (_lastCheckFuture != null) {
      return await _lastCheckFuture!;
    }

    final completer = Completer<Map<String, dynamic>>();
    _lastCheckFuture = completer.future;

    try {
      final serverLanguages = await getLanguagePacks(true);
      if (serverLanguages.isEmpty) {
        final result = {
          'status': 'no_server_languages',
          'serverLanguages': serverLanguages,
        };
        _lastCheckResult = result;
        _lastCheckTime = DateTime.now();
        completer.complete(result);
        _lastCheckFuture = null;
        return result;
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

      final result = {
        'status': problematic.isEmpty ? 'all_ok' : 'some_problem',
        'problematic': problematic,
        'details': problemsDetails,
        'serverLanguages': serverLanguages,
      };
      _lastCheckResult = result;
      _lastCheckTime = DateTime.now();
      completer.complete(result);
      _lastCheckFuture = null;
      return result;
    } catch (e) {
      final result = {
        'status': 'error',
        'error': e.toString(),
      };
      _lastCheckResult = result;
      _lastCheckTime = DateTime.now();
      completer.complete(result);
      _lastCheckFuture = null;
      return result;
    }
  }

  Future<List<String>> _downloadLanguages(List<String> langs) async {
    List<String> results = [];
    for (var lang in langs) {
      final res = await downloadLanguagePack(lang);
      results.add('$lang: $res');
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Connectivity'),
      ),
      body: Column(
        children: [
          ListTile(
            title: const Text('Server Status'),
            subtitle: Text(_serverUrl.isNotEmpty ? _serverUrl : 'Not configured'),
            trailing: Consumer<ConnectionStateProvider>(
              builder: (context, provider, child) {
                return IconButton(
                  icon: Icon(
                    provider.connectionState == HttpStatus.ok
                        ? Icons.cloud_done
                        : Icons.cloud_off,
                    color: provider.connectionState == HttpStatus.ok
                        ? Colors.green
                        : Colors.red,
                  ),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Server Status'),
                          content: Text(
                              provider.connectionState == HttpStatus.ok
                                  ? 'Connected to server successfully.'
                                  : provider.connectionState == HttpStatus.notFound
                                  ? 'Server URL not configured.'
                                  : 'Failed to connect to server. Please check your server URL and internet connection.'
                          ),
                          actions: [
                            if (provider.connectionState != HttpStatus.ok)
                              TextButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                                },
                                child: const Text('Settings'),
                              ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        )
                    );
                  },
                );
              },
            ),
          ),
          ListTile(
            title: const Text('Account Status'),
            subtitle: Text(_username.isNotEmpty ? _username : 'Not configured'),
            trailing: Consumer2<AccountStateProvider, ConnectionStateProvider>(
              builder: (context, provider, connection, child) {
                return IconButton(
                  icon: Icon(
                    provider.connectionState == HttpStatus.ok
                        ? Icons.cloud_done
                        : connection.connectionState == HttpStatus.ok && provider.connectionState == HttpStatus.notFound
                        ? Icons.manage_accounts
                        : connection.connectionState == HttpStatus.ok && provider.connectionState == HttpStatus.unauthorized
                        ? Icons.login
                        : Icons.cloud_off,
                    color: provider.connectionState == HttpStatus.ok
                        ? Colors.green
                        : connection.connectionState == HttpStatus.ok && (provider.connectionState == HttpStatus.notFound || provider.connectionState == HttpStatus.unauthorized)
                        ? Colors.orange
                        : Colors.red,
                  ),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Account Status'),
                          content: Text(
                              provider.connectionState == HttpStatus.ok
                                  ? 'Logged in successfully.'
                                  : connection.connectionState == HttpStatus.ok && provider.connectionState == HttpStatus.notFound
                                  ? 'Account not found. Please check your username or create a new account.'
                                  : connection.connectionState == HttpStatus.ok && provider.connectionState == HttpStatus.unauthorized
                                  ? 'Unauthorized. Please check your password.'
                                  : 'Failed to connect to server. Please check your server URL and internet connection.'
                          ),
                          actions: [
                            if (provider.connectionState == HttpStatus.notFound && connection.connectionState == HttpStatus.ok)
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final connProvider = Provider.of<ConnectionStateProvider>(context, listen: false);
                                  final accProvider = Provider.of<AccountStateProvider>(context, listen: false);
                                  final server = await getConfig("server_url");
                                  final user = await getConfig("username");
                                  final pass = await getConfig("password");
                                  await createAccountUI(
                                    server != null && server.isNotEmpty ? server : _serverUrl,
                                    user != null && user.isNotEmpty ? user : _username,
                                    pass != null && pass.isNotEmpty ? pass : _password
                                  );
                                  connProvider.forceCheck();
                                  accProvider.forceCheck();
                                },
                                child: const Text('Create account'),
                              ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        )
                    );
                  },
                );
              },
            ),
          ),
          ListTile(
            title: const Text('Languages'),
            subtitle: FutureBuilder<List<String>>(
              future: getLanguagePacks(true),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text('Languages available: ${snapshot.data!.length}');
                }
                return const Text('');
              },
            ),
            trailing: Consumer<ConnectionStateProvider>(
              builder: (context, connProvider, child) {
                return FutureBuilder<Map<String, dynamic>>(
                  future: _checkLanguagesForServer(),
                  builder: (context, snapshot) {
                    final data = snapshot.data ?? {};
                    final status = data['status'] as String? ?? 'error';
                    return IconButton(
                      icon: Icon(
                        status == 'all_ok'
                          ? Icons.cloud_done
                          : status == 'some_problem'
                          ? Icons.file_download_off
                          : Icons.cloud_off,
                        color: status == 'all_ok'
                            ? Colors.green
                            : status == 'some_problem'
                            ? Colors.orange
                            : Colors.red,
                      ),
                      onPressed: () async {
                        if (connProvider.connectionState != HttpStatus.ok) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Languages'),
                              content: const Text('Failed to connect to server. Please check your server URL and internet connection.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        final result = await _checkLanguagesForServer(force: true);
                        final status2 = result['status'] as String? ?? 'error';
                        if (!context.mounted) return;
                        showDialog(
                          context: context,
                          builder: (dialogContext) {
                            if (status2 == 'no_server_languages') {
                              return AlertDialog(
                                title: const Text('Languages'),
                                content: const Text('No languages available on server.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext),
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            }

                            if (status2 == 'all_ok') {
                              return AlertDialog(
                                title: const Text('Languages'),
                                content: const Text('All languages are correct.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext),
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            }

                            final List<String> problematic = List<String>.from(result['problematic'] ?? []);
                            final Map<String, String> details = Map<String, String>.from(result['details'] ?? {});

                            return AlertDialog(
                              title: const Text('Languages'),
                              content: SingleChildScrollView(
                                child: ListBody(
                                  children: [
                                    const Text('The following languages are missing or invalid:'),
                                    const SizedBox(height: 8),
                                    Text(problematic.join(', ')),
                                    const SizedBox(height: 8),
                                    Text(problematic.map((l) => '$l: ${details[l]}').join('\n')),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(dialogContext);
                                    if (problematic.isEmpty) return;
                                    await showDialog(
                                      context: context,
                                      builder: (downloadCtx) {
                                        return AlertDialog(
                                          title: const Text('Downloading languages'),
                                          content: FutureBuilder<List<String>>(
                                            future: _downloadLanguages(problematic),
                                            builder: (dCtx, dSnap) {
                                              if (dSnap.connectionState != ConnectionState.done) {
                                                return const SizedBox(
                                                  height: 80,
                                                  child: Center(child: CircularProgressIndicator()),
                                                );
                                              }
                                              final List<String> results = dSnap.data ?? [];
                                              return SingleChildScrollView(
                                                child: Text(results.join('\n')),
                                              );
                                            },
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(downloadCtx),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (!mounted) return;
                                    setState(() {
                                      _invalidateLanguageCheckCache();
                                    });
                                    await _checkLanguagesForServer(force: true);
                                  },
                                  child: const Text('Download'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          )
        ],
      )
    );
  }
}