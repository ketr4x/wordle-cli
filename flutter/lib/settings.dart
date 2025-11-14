import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:wordle/utils.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _username = '';
  String _password = '';
  String _serverUrl = '';
  String _wordleLanguage = '';
  String _rankedLanguage = '';
  PackageInfo? packageInfo;
  final FocusNode _serverUrlFocusNode = FocusNode();
  late TextEditingController _serverUrlController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _serverUrlController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _loadUsername();
    _loadPassword();
    _loadServerUrl();
    _loadPackageInfo();
    _serverUrlFocusNode.addListener(_onServerUrlFocusChange);
  }

  @override
  void dispose() {
    _serverUrlFocusNode.dispose();
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onServerUrlFocusChange() async {
    if (!_serverUrlFocusNode.hasFocus) {
      final trimmed = _serverUrl.trim();
      if (!trimmed.startsWith('http://') &&
          !trimmed.startsWith('https://') &&
          trimmed.isNotEmpty) {
        if (await checkConnectionState('https://$trimmed') == HttpStatus.ok) {
          _serverUrl = 'https://$trimmed';
        } else {
          _serverUrl = 'http://$trimmed';
        }
        _serverUrlController.text = _serverUrl;
      }
      if (!mounted) return;
      final connProvider = Provider.of<ConnectionStateProvider>(context, listen: false);
      final accProvider = Provider.of<AccountStateProvider>(context, listen: false);
      setConfig("server_url", _serverUrl);
      connProvider.forceCheck();
      accProvider.forceCheck();
    }
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      packageInfo = info;
    });
  }
  Future<void> _loadUsername() async {
    final username = await getConfig("username");
    setState(() {
      _username = username ?? '';
      _usernameController.text = _username;
    });
  }

  Future<void> _loadPassword() async {
    final password = await getConfig("password");
    setState(() {
      _password = password ?? '';
      _passwordController.text = _password;
    });
  }

  Future<void> _loadServerUrl() async {
    final serverUrl = await getConfig("server_url");
    setState(() {
      _serverUrl = serverUrl ?? 'https://wordle.ketrax.ovh';
      _serverUrlController.text = _serverUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Settings'),
      ),
      body: Column(
        children: [
          ListTile(
            title: const Text('Dark Mode'),
            trailing: Switch.adaptive(
              value: AdaptiveTheme.of(context).mode.isDark,
              onChanged: (value) {
                if (value) {
                  AdaptiveTheme.of(context).setDark();
                } else {
                  AdaptiveTheme.of(context).setLight();
                }
              },
            ),
          ),
          ListTile(
            title: const Text('Username'),
            trailing: SizedBox(
              width: 200,
              child: TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: _username.isNotEmpty ? _username : 'Enter your username',
                ),
                onChanged: (value) async {
                  setState(() {
                    _username = value;
                  });
                  final connProvider = Provider.of<ConnectionStateProvider>(context, listen: false);
                  final accProvider = Provider.of<AccountStateProvider>(context, listen: false);
                  await setConfig("username", value);
                  connProvider.forceCheck();
                  accProvider.forceCheck();
                },
              ),
            )
          ),
          ListTile(
            title: const Text('Password'),
            trailing: SizedBox(
              width: 200,
              child: TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: _password.isNotEmpty ? '••••••••' : 'Enter your password',
                ),
                obscureText: true,
                onChanged: (value) async {
                  setState(() {
                    _password = value;
                  });
                  final connProvider = Provider.of<ConnectionStateProvider>(context, listen: false);
                  final accProvider = Provider.of<AccountStateProvider>(context, listen: false);
                  await setConfig("password", value);
                  connProvider.forceCheck();
                  accProvider.forceCheck();
                },
              ),
            )
          ),
          ListTile(
            title: const Text('Server URL'),
            trailing: SizedBox(
              width: 200,
              child: TextField(
                controller: _serverUrlController,
                focusNode: _serverUrlFocusNode,
                decoration: InputDecoration(
                  hintText: _serverUrl.isNotEmpty ? _serverUrl : 'like wordle.ketrax.ovh',
                ),
                  onChanged: (value) {
                    _serverUrl = value;
                  }
              ),
            )
          ),
          ListTile(
            title: const Text('Wordle Language'),
            trailing: SizedBox(
              width: 200,
              child: FutureBuilder<List<Object?>>(
                future: Future.wait([getLanguagePacks(false), getConfig('game_lang')]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Container(
                      alignment: AlignmentGeometry.centerRight,
                      child: const SizedBox(
                        height: 36,
                        width: 36,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final data = snapshot.data ?? [];
                  final languages = (data.isNotEmpty && data[0] is List) ? (data[0] as List).cast<String>() : <String>['en'];
                  final saved = (data.length > 1 && data[1] is String)
                    ? data[1] as String
                    : (_wordleLanguage.isNotEmpty
                    ? _wordleLanguage
                    : (languages.isNotEmpty
                    ? languages.first
                    : 'en')
                    );
                  final selected = languages.contains(saved)
                    ? saved
                    : (languages.isNotEmpty
                    ? languages.first
                    : 'en'
                    );
                  printDebugInfo('$languages, $saved, $selected');

                  return DropdownButtonFormField<String>(
                    initialValue: selected,
                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsetsGeometry.symmetric(vertical: 8)),
                    items: languages.map((lang) => DropdownMenuItem(
                      value: lang,
                      child: Text(lang)
                    )).toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      await setConfig('game_lang', value);
                      setState(() {
                        _wordleLanguage = value;
                      });
                    }
                  );
                }
              )
            )
          ),
          ListTile(
            title: const Text('Ranked Language'),
            trailing: SizedBox(
              width: 200,
              child: FutureBuilder<List<Object?>>(
                future: Future.wait([getLanguagePacks(true), getConfig('ranked_game_lang')]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Container(
                      alignment: AlignmentGeometry.centerRight,
                      child: const SizedBox(
                        height: 36,
                        width: 36,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final data = snapshot.data ?? [];
                  final languages = (data.isNotEmpty && data[0] is List) ? (data[0] as List).cast<String>() : <String>['en'];
                  final saved = (data.length > 1 && data[1] is String)
                    ? data[1] as String
                    : (_rankedLanguage.isNotEmpty
                    ? _rankedLanguage
                    : (languages.isNotEmpty
                    ? languages.first
                    : 'en')
                  );
                  final selected = languages.contains(saved)
                    ? saved
                    : (languages.isNotEmpty
                    ? languages.first
                    : 'en'
                  );
                  printDebugInfo('$languages, $saved, $selected');

                  return DropdownButtonFormField<String>(
                    initialValue: selected,
                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsetsGeometry.symmetric(vertical: 8)),
                    items: languages.map((lang) => DropdownMenuItem(
                      value: lang,
                      child: Text(lang)
                    )).toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      await setConfig('ranked_game_lang', value);
                      setState(() {
                        _wordleLanguage = value;
                      });
                    }
                  );
                }
              )
            )
          ),
          ListTile(
            title: const Text('About'),
            trailing: Text(packageInfo?.version ?? ''),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Wordix',
                applicationVersion: packageInfo?.version ?? 'Unknown',
                /*applicationIcon: Image.asset( TODO: add app icon
                  'assets/app_icon.png',
                  width: 48,
                  height: 48,
                ),*/
                applicationLegalese: 'Copyright ketr4x, 2025. '
                  '\nLicensed under BSD-3-Clause License.',
              );
            },
          ),
          ListTile(
            title: const Text('GitHub'),
            onTap: () async {
              final url = Uri.parse('https://github.com/ketr4x/wordle-cli');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          )
        ],
      )
    );
  }
}