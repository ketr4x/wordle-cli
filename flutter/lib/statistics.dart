import 'package:flutter/material.dart';
import 'utils.dart';
import 'random.dart';
import 'daily.dart';
import 'leaderboard.dart';
import 'ranked.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final int _selectedIndex = 4;

  double? avgTime;
  int? matches;
  int? points;
  int? wins;
  Map<String, dynamic>? wordFreq;
  String? registeredOn;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final user = await getConfig('username');
      final auth = await getConfig('password');
      final serverUrl = await getConfig('server_url');
      if (serverUrl == null || user == null || auth == null) {
        setState(() {
          error = 'Missing configuration. Please check your settings.';
          loading = false;
        });
        return;
      }
      final url = '$serverUrl/online/stats?user=$user&auth=$auth';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        setState(() {
          error = 'Error fetching stats: ${response.statusCode}\n'
                  'If you are running Flutter Web, check CORS settings on your server.';
          loading = false;
        });
        return;
      }
      final statistics = json.decode(response.body);
      setState(() {
        avgTime = statistics['avg_time'] != null
            ? double.tryParse(statistics['avg_time'].toString())
            : null;
        matches = statistics['matches'] is int
            ? statistics['matches']
            : int.tryParse(statistics['matches']?.toString() ?? '');
        points = statistics['points'] is int
            ? statistics['points']
            : int.tryParse(statistics['points']?.toString() ?? '');
        wins = statistics['wins'] is int
            ? statistics['wins']
            : int.tryParse(statistics['wins']?.toString() ?? '');
        wordFreq = statistics['word_freq'] != null
            ? Map<String, dynamic>.from(statistics['word_freq'])
            : {};
        registeredOn = statistics['registered_on']?.toString();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to fetch statistics: $e\n'
                'If you are running Flutter Web, check CORS settings on your server.';
        loading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    Widget page;
    switch (index) {
      case 0:
        page = const RandomPage();
        break;
      case 1:
        page = const DailyPage();
        break;
      case 2:
        page = const RankedPage();
        break;
      case 3:
        page = const LeaderboardPage();
        break;
      case 4:
        page = const StatsPage();
        break;
      default:
        return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, "Statistics"),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Registered on ${registeredOn ?? '-'}",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Average time per game: ${avgTime != null ? avgTime!.toStringAsFixed(2) : '-'}s",
                        ),
                        Text("Total matches: ${matches ?? '-'}"),
                        Text("Total wins: ${wins ?? '-'}"),
                        Text("Total losses: ${(matches != null && wins != null) ? (matches! - wins!) : '-'}"),
                        Text(
                          "Winrate: ${(matches != null && wins != null && matches! > 0) ? ((wins! / matches!) * 100).toStringAsFixed(2) : '-'}%",
                        ),
                        Text("ELO: ${points ?? '-'}"),
                        const SizedBox(height: 16),
                        Text("Most used words:", style: Theme.of(context).textTheme.titleMedium),
                        if (wordFreq != null && wordFreq!.isNotEmpty)
                          ...(() {
                            final entries = wordFreq!.entries.toList();
                            entries.sort((a, b) => (b.value as int).compareTo(a.value as int));
                            return entries
                                .map((entry) => Text("${entry.key}: ${entry.value}"))
                                .toList();
                          })()
                        else
                          const Text("No words recorded yet."),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: buildBottomNavigationBar(
        context,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}