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
                                    SettingsPage;
                                    Navigator.pop(context);
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
              trailing: Consumer<AccountStateProvider>(
                builder: (context, provider, child) {
                  return IconButton(
                    icon: Icon(
                      provider.connectionState == HttpStatus.ok
                          ? Icons.cloud_done
                          : provider.connectionState == HttpStatus.notFound
                          ? Icons.manage_accounts
                          : provider.connectionState == HttpStatus.unauthorized
                          ? Icons.login
                          : Icons.cloud_off,
                      color: provider.connectionState == HttpStatus.ok
                          ? Colors.green
                          : provider.connectionState == HttpStatus.notFound || provider.connectionState == HttpStatus.unauthorized
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
                                    : provider.connectionState == HttpStatus.notFound
                                    ? 'Account not found. Please check your username or create a new account.'
                                    : provider.connectionState == HttpStatus.unauthorized
                                    ? 'Unauthorized. Please check your password.'
                                    : 'Failed to connect to server. Please check your server URL and internet connection.'
                            ),
                            actions: [
                              if (provider.connectionState == HttpStatus.notFound)
                                TextButton(
                                  onPressed: () {
                                    createAccountUI(context, _serverUrl, _username, _password);
                                    Navigator.pop(context);
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
            )
          ],
        )
    );
  }
}