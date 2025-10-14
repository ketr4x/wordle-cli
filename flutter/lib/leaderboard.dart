import 'package:flutter/material.dart';
import 'utils.dart';
import 'random.dart';
import 'daily.dart';
import 'ranked.dart';
import 'statistics.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final int _selectedIndex = 3;
  LeaderboardData? leaderboardData;
  bool loading = true;
  String? error;
  String? currentUser;

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final user = await getConfig('username');
      final auth = await getConfig('password');
      
      if (user == null || auth == null) {
        setState(() {
          error = 'Username or password not configured';
          loading = false;
        });
        return;
      }

      currentUser = user;
      final data = await getLeaderboard('basic', user, auth);
      
      setState(() {
        leaderboardData = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
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

  Widget buildLeaderboardColumn(String title, String emoji, List<Map<String, dynamic>> data, String valueKey, String? unit) {
    return Expanded(
      child: Column(
        children: [
          Text('$emoji $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...List.generate(10, (index) {
            if (index < data.length) {
              final item = data[index];
              final username = item['username'] ?? '';
              final value = item[valueKey];
              final isCurrentUser = username == currentUser;
              
              String displayValue;
              if (valueKey == 'avg_time') {
                displayValue = '${value.toStringAsFixed(1)}s';
              } else if (valueKey == 'winrate') {
                displayValue = '${(value * 100).toStringAsFixed(1)}%';
              } else {
                displayValue = value.toString();
              }
              
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCurrentUser ? Colors.yellow.withOpacity(0.3) : null,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${index + 1}.',
                    style: TextStyle(
                      fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                      color: isCurrentUser ? Colors.orange : Colors.black,
                    )),
                    Expanded(
                      child: Text(
                        username.length > 8 ? username.substring(0, 8) : username,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                          color: isCurrentUser ? Colors.orange : Colors.black,
                        ),
                      ),
                    ),
                    Text(displayValue),
                    if (isCurrentUser) const Icon(Icons.star, size: 16, color: Colors.orange),
                  ],
                ),
              );
            } else {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text('${index + 1}. ---'),
              );
            }
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, "Leaderboard"),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchLeaderboard,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : leaderboardData == null
                  ? const Center(child: Text('No data available'))
                  : RefreshIndicator(
                      onRefresh: fetchLeaderboard,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildLeaderboardColumn('ELO', '📊', leaderboardData!.topPoints, 'points', null),
                                const SizedBox(width: 8),
                                buildLeaderboardColumn('MATCHES', '🎮', leaderboardData!.topMatches, 'matches', null),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildLeaderboardColumn('AVG TIME', '⚡', leaderboardData!.topAvgTime, 'avg_time', 's'),
                                const SizedBox(width: 8),
                                buildLeaderboardColumn('WINRATE', '🎯', leaderboardData!.topWinrate, 'winrate', '%'),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Your Rankings', style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 8),
                                    Text('ELO: #${leaderboardData!.userPosition['points'] ?? '-'}'),
                                    Text('Matches: #${leaderboardData!.userPosition['matches'] ?? '-'}'),
                                    Text('Avg Time: #${leaderboardData!.userPosition['avg_time'] ?? '-'}'),
                                    Text('Winrate: #${leaderboardData!.userPosition['winrate'] ?? '-'}'),
                                  ],
                                ),
                              ),
                            ),
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