import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wordle/utils.dart';
import 'package:provider/provider.dart';

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  State<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  String _username = '';
  String _password = '';
  String _newUsername = '';
  String _newPassword = '';
  String _serverUrl = '';
  String _result = '';
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadPassword();
    _loadServerUrl();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    final username = await getConfig("username");
    setState(() {
      _username = username ?? '';
      _newUsername = _username;
      _usernameController.text = _newUsername;
    });
  }

  Future<void> _loadPassword() async {
    final password = await getConfig("password");
    setState(() {
      _password = password ?? '';
      _newPassword = _password;
      _passwordController.text = _newPassword;
    });
  }

  Future<void> _loadServerUrl() async {
    final serverUrl = await getConfig("server_url");
    setState(() {
      _serverUrl = serverUrl!;
    });
  }

  Future<String> applyChanges() async {
    try {
      final url = '$_serverUrl/online/change_data';
      String mode = (_password == _newPassword && _username == _newUsername) ? 'nothing' : (_password != _newPassword && _username != _newUsername) ? 'everything' : (_password != _newPassword) ? 'password' : 'username';
      if (mode == 'nothing') {
        return 'Nothing to change.';
      }

      final response = (mode == 'everything' || mode == 'username') ? (await http.get(Uri.parse('$url/user?user=$_username&auth=$_password&new_user=$_newUsername')).timeout(const Duration(seconds: 7))) : http.Response('', 400);
      final response2 = (mode == 'everything' || mode == 'password') ? (await http.get(Uri.parse('$url/auth?user=${mode == 'password' ? _username : _newUsername}&auth=$_password&new_auth=$_newPassword')).timeout(const Duration(seconds: 7))) : http.Response('', 400);

      if (response.statusCode == 200 && response2.statusCode == 200) {
        return 'Changed the username and password successfully';
      } else {
        if (response.statusCode == 200 || response2.statusCode == 200) {
          return (response.statusCode == 200 ? 'Changed the username successfully' : 'Changed the password successfully');
        } else {
          return 'Failed to change the account details: ${response.body} ${response2.body}';
        }
      }
    } catch (e) {
      return 'Failed to change the account details: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Account Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: const Text('Current username'),
              trailing: SizedBox(
                width: 200,
                child: TextField(
                  readOnly: true,
                  controller: TextEditingController(text: _username),
                )
              )
            ),
            ListTile(
              title: const Text('Current password'),
              trailing: SizedBox(
                width: 200,
                  child: TextField(
                    readOnly: true,
                    controller: TextEditingController(text: '•'*_password.length),
                  )
              )
            ),
            ListTile(
              title: const Text('New username'),
              trailing: SizedBox(
                width: 200,
                child: TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: _newUsername.isNotEmpty ? _newUsername : 'Enter your new username',
                  ),
                  onChanged: (value) async {
                    setState(() {
                      _newUsername = value;
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
              title: const Text('New password'),
              trailing: SizedBox(
                width: 200,
                child: TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: _newPassword.isNotEmpty ? '•'*_newPassword.length : 'Enter your new password',
                  ),
                  obscureText: true,
                  onChanged: (value) async {
                    setState(() {
                      _newPassword = value;
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
            Padding(
              padding: EdgeInsetsGeometry.symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed: () async {
                  String result = await applyChanges();
                  setState(() {
                    _result = result;
                    if (result.contains('Changed')) {
                      _password = _newPassword;
                      _username = _newUsername;
                    }
                  });
                  if (_result.contains('Failed to change the account details.')) {
                    showErrorToast(_result, long: true);
                  }
                },
                child: Text('Apply')
              )
            ),
            if (_result != '')
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _result,
                  style: TextStyle(fontSize: 16, color: (_result.contains('Failed to change the account details.') ? Colors.red : Theme.of(context).colorScheme.onSurface)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}