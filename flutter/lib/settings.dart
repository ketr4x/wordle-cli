import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:wordle/utils.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _username = '';
  String _password = '';

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadPassword();
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
                  await setConfig("username", value);
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
                  await setConfig("password", value);
                },
              ),
            )
          ),
          const ListTile(
            title: Text('About'),
            subtitle: Text('Wordle made with Flutter.'),
            trailing: Text('v1.0'),
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