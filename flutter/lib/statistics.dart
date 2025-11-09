import 'package:flutter/material.dart';
import 'utils.dart';
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
          error = 'Error fetching stats: ${response.statusCode}\n';
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
        error = 'Failed to fetch statistics: $e\n';
        loading = false;
      });
    }
  }

  Widget _buildWord(MapEntry<String, dynamic> entry, BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsetsGeometry.all(8),
        child: Center(
          child: Text(
            "${entry.key} - ${entry.value}",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, dynamic>> entries = (wordFreq != null)
      ? wordFreq!.entries.toList()
      : <MapEntry<String, dynamic>>[];
    entries.sort((a, b) {
      final ai = a.value is int ? a.value as int : int.tryParse(a.value?.toString() ?? '0') ?? 0;
      final bi = b.value is int ? b.value as int : int.tryParse(b.value?.toString() ?? '0') ?? 0;
      return bi.compareTo(ai);
    });

    return Scaffold(
      appBar: buildAppBar(context, "Statistics"),
      body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchStats,
                child: const Text('Retry'),
              ),
            ],
          ),
        )
        : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Registered on ${registeredOn ?? '0'}",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  "Average time per game: ${avgTime != null ? avgTime!.toStringAsFixed(2) : '0'}s",
                ),
                Text("Total matches: ${matches ?? '0'}"),
                Text("Total wins: ${wins ?? '0'}"),
                Text("Total losses: ${(matches != null && wins != null) ? (matches! - wins!) : '0'}"),
                Text(
                  "Winrate: ${(matches != null && wins != null && matches! > 0) ? ((wins! / matches!) * 100).toStringAsFixed(2) : '0'}%",
                ),
                Text("ELO: ${points ?? '0'}"),
                const SizedBox(height: 16),
                Text("Most used words:", style: Theme.of(context).textTheme.titleMedium),
                if (wordFreq != null && wordFreq!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entries.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2
                    ),
                    itemBuilder: (context, index) => _buildWord(entries[index], context)
                  )
                ] else ...[
                  const Text("No words recorded yet."),
                ],
              ],
            ),
          ),
        ),
      bottomNavigationBar: buildBottomNavigationBar(
        context,
        currentIndex: _selectedIndex,
      ),
    );
  }
}