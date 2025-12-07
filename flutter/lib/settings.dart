import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:wordle/utils.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;

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
  String _aiLanguage = '';
  String _aiApiUrl = '';
  String _aiApiKey = '';
  bool _aiKeyVisible = false;
  String _aiApiModel = '';
  PackageInfo? packageInfo;
  final FocusNode _serverUrlFocusNode = FocusNode();
  late TextEditingController _serverUrlController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _aiLanguageController;
  late TextEditingController _aiApiUrlController;
  late TextEditingController _aiApiKeyController;
  late TextEditingController _aiApiModelController;
  late Future<List<String>> _aiModelsFuture;
  late Future<List<Object?>> _wordleLanguagesFuture;
  late Future<List<Object?>> _rankedLanguagesFuture;

  static const excluded = [
    'google/gemini-2.5-flash-image',
    'whisper',
    'tts',
    'dall-e',
    'embedding',
    'moderation',
  ];

  @override
  void initState() {
    super.initState();
    _serverUrlController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _aiLanguageController = TextEditingController();
    _aiApiUrlController = TextEditingController();
    _aiApiKeyController = TextEditingController();
    _aiApiModelController = TextEditingController();
    _aiModelsFuture = getAIModels();
    _wordleLanguagesFuture = Future.wait([getLanguagePacks(false), getConfig('game_lang')]);
    _rankedLanguagesFuture = Future.wait([getLanguagePacks(true), getConfig('game_lang')]);
    _loadUsername();
    _loadPassword();
    _loadServerUrl();
    _loadAILanguage();
    _loadAIApiUrl();
    _loadAIApiKey();
    _loadAIApiModel();
    _loadPackageInfo();
    _serverUrlFocusNode.addListener(_onServerUrlFocusChange);
  }

  @override
  void dispose() {
    _serverUrlFocusNode.dispose();
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _aiLanguageController.dispose();
    _aiApiUrlController.dispose();
    _aiApiModelController.dispose();
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
      _serverUrl = serverUrl ?? '';
      _serverUrlController.text = _serverUrl;
    });
  }

  Future<void> _loadAILanguage() async {
    final aiLanguage = await getConfig("ai_game_lang");
    setState(() {
      _aiLanguage = aiLanguage ?? '';
      _aiLanguageController.text = _aiLanguage;
    });
  }

  Future<void> _loadAIApiUrl() async {
    final aiApiUrl = await getConfig("ai_api_url");
    setState(() {
      _aiApiUrl = aiApiUrl ?? '';
      _aiApiUrlController.text = _aiApiUrl;
      _aiModelsFuture = getAIModels();
    });
  }

  Future<void> _loadAIApiKey() async {
    final aiApiKey = await getConfig("ai_api_key");
    setState(() {
      _aiApiKey = aiApiKey ?? '';
      _aiApiKeyController.text = _aiApiKey;
      _aiModelsFuture = getAIModels();
    });
  }

  Future<void> _loadAIApiModel() async {
    final aiApiModel = await getConfig("ai_api_model");
    setState(() {
      _aiApiModel = aiApiModel ?? '';
      _aiApiModelController.text = _aiApiModel;
    });
  }

  Future<List<String>> getAIModels() async {
    final storedApiUrl = await getConfig('ai_api_url');
    final resolvedApiUrl = (storedApiUrl?.trim().isNotEmpty ?? false)
      ? storedApiUrl!.trim()
      : _aiApiUrlController.text.trim();

    final storedKey = await getConfig('ai_api_key');
    final apiKey = (storedKey?.trim().isNotEmpty ?? false)
      ? storedKey!.trim()
      : _aiApiKeyController.text.trim();
    if (apiKey.isEmpty) {
      return [];
    }

    try {
      final response = await http.get(Uri.parse('$resolvedApiUrl/v1/models')).timeout(const Duration(seconds: 7));
      List<String> models = [];
      if (response.statusCode == 200) {
        final modelsRaw = jsonDecode(response.body)["data"];
        for (final model in modelsRaw) {
          if (!excluded.contains(model["id"])) models.add(model["id"]);
        }
      }
      printDebugInfo('Loaded ${models.length} models');
      return models;
    } catch (error, stack) {
      printDebugInfo('Failed to load AI models: $error');
      debugPrintStack(stackTrace: stack);
      showErrorToast('Failed to load AI models: $error');
      return [];
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: AdaptiveTheme.of(context).mode.isDark,
              onChanged: (value) {
                if (value) {
                  AdaptiveTheme.of(context).setDark();
                } else {
                  AdaptiveTheme.of(context).setLight();
                }
              },
            ),
            ListTile(
              title: const Text('Username'),
              trailing: SizedBox(
                width: 220,
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
                width: 220,
                child: TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: _password.isNotEmpty ? '•'*_password.length : 'Enter your password',
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
                width: 220,
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
                width: 220,
                child: FutureBuilder<List<Object?>>(
                  future: _wordleLanguagesFuture,
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
                      iconDisabledColor: Theme.of(context).colorScheme.onSurface,
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
                width: 220,
                child: FutureBuilder<List<Object?>>(
                  future: _rankedLanguagesFuture,
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
                      iconDisabledColor: Theme.of(context).colorScheme.onSurface,
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
                          _rankedLanguage = value;
                        });
                      }
                    );
                  }
                )
              )
            ),
            ListTile(
              title: const Text('AI Language'),
              trailing: SizedBox(
                width: 220,
                child: TextField(
                  controller: _aiLanguageController,
                  decoration: InputDecoration(hintText: _aiLanguage.isNotEmpty ? _aiLanguage : 'i.e. English or en'),
                  onChanged: (value) async {
                    _aiLanguage = value;
                    await setConfig('ai_game_lang', value);
                  }
                ),
              )
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DefaultTabController(
                initialIndex: 0,
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      tabs: <Widget>[
                        Tab(text: 'Public AI', icon: Icon(Icons.public)),
                        Tab(text: 'Custom', icon: Icon(Icons.private_connectivity)),
                      ]
                    ),
                    SizedBox(
                      height: 200,
                      child: TabBarView(
                        children: <Widget>[
                          SingleChildScrollView(
                            child: Column(
                              children: [
                                Text('data')
                              ],
                            ),
                          ),
                          SingleChildScrollView(
                            child: Column(
                              children: [
                                ListTile(
                                  title: const Text('AI API URL'),
                                  subtitle: const Text('Leave blank for the OpenAI API'),
                                  trailing: SizedBox(
                                    width: 220,
                                    child: TextField(
                                      controller: _aiApiUrlController,
                                      decoration: InputDecoration(
                                        hintText: _aiApiUrl.isNotEmpty ? _aiApiUrl : 'https://ai.hackclub.com/proxy',
                                      ),
                                      onChanged: (value) async {
                                        setState(() {
                                          _aiApiUrl = value;
                                          _aiModelsFuture = getAIModels();
                                        });
                                        await setConfig('ai_api_url', value);
                                      }
                                    ),
                                  )
                                ),
                                ListTile(
                                  title: const Text('AI API key'),
                                  trailing: SizedBox(
                                    width: 220,
                                    child: TextField(
                                      controller: _aiApiKeyController,
                                      obscureText: !_aiKeyVisible,
                                      decoration: InputDecoration(
                                        hintText: _aiApiKey.isEmpty ? 'Enter your API key' : null,
                                        suffixIcon: _aiApiKey.isNotEmpty
                                          ? IconButton(
                                            icon: Icon(_aiKeyVisible ? Icons.visibility_off : Icons.visibility),
                                            onPressed: () {
                                              setState(() {
                                                _aiKeyVisible = !_aiKeyVisible;
                                              });
                                            },
                                          )
                                          : SizedBox.shrink()
                                      ),
                                      onChanged: (value) async {
                                        setState(() {
                                          _aiApiKey = value;
                                        });
                                        await setConfig('ai_api_key', value);
                                      }
                                    ),
                                  )
                                ),
                                ListTile(
                                  title: const Text('AI model'),
                                  trailing: SizedBox(
                                    width: 220,
                                    child: FutureBuilder<List<Object?>>(
                                      future: Future.wait([_aiModelsFuture, getConfig('ai_api_model')]),
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
                                        final models = (data.isNotEmpty && data[0] is List) ? (data[0] as List).cast<String>() : <String>[];
                                        final saved = (data.length > 1 && data[1] is String)
                                          ? data[1] as String
                                          : (_aiApiModel.isNotEmpty
                                          ? _aiApiModel
                                          : (models.isNotEmpty
                                          ? models.first
                                          : '')
                                        );
                                        final selected = models.contains(saved)
                                          ? saved
                                          : models.isNotEmpty
                                          ? models.first
                                          : '';
                                        printDebugInfo('$models, $saved, $selected');
                            
                                        return DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          isDense: true,
                                          iconDisabledColor: Theme.of(context).colorScheme.onSurface,
                                          initialValue: selected,
                                          decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsetsGeometry.symmetric(vertical: 8)),
                                          items: models.map((model) => DropdownMenuItem(
                                            value: model,
                                            child: Text(model)
                                          )).toList(),
                                          onChanged: (value) async {
                                            if (value == null) return;
                                            await setConfig('ai_api_model', value);
                                            setState(() {
                                              _aiApiModel = value;
                                            });
                                          }
                                        );
                                      }
                                    )
                                  )
                                ),
                              ]
                            ),
                          )
                        ]
                      ),
                    )
                  ]
                )
              ),
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
        ),
      )
    );
  }
}