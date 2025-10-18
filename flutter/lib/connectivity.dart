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
              subtitle: const Text('Available languages depend on server configuration.'),
            )
          ],
        )
    );
  }
}