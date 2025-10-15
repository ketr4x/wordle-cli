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
  late PackageInfo packageInfo;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadPassword();
    _loadServerUrl();
    _loadPackageInfo();
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
              width: 180,
              child: TextField(
                controller: TextEditingController(text: _username)
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: _username.length),
                  ),
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
              width: 180,
              child: TextField(
                controller: TextEditingController(text: _password)
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: _password.length),
                  ),
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
                width: 180,
                child: TextField(
                  controller: TextEditingController(text: _serverUrl)
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: _serverUrl.length),
                    ),
                  decoration: InputDecoration(
                    hintText: _serverUrl.isNotEmpty ? _serverUrl : 'Enter your server URL (like http://wordle.ketrax.ovh)',
                  ),
                  onChanged: (value) async {
                    setState(() {
                      _serverUrl = value;
                    });
                    final connProvider = Provider.of<ConnectionStateProvider>(context, listen: false);
                    final accProvider = Provider.of<AccountStateProvider>(context, listen: false);
                    await setConfig("server_url", value);
                    connProvider.forceCheck();
                    accProvider.forceCheck();
                  },
                ),
              )
          ),
          ListTile(
            title: const Text('About'),
            trailing: Text(packageInfo.version),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Wordix',
                applicationVersion: packageInfo.version,
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