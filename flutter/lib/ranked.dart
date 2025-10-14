import 'package:flutter/material.dart';
import 'utils.dart';
import 'random.dart';
import 'daily.dart';
import 'leaderboard.dart';
import 'statistics.dart';

class RankedPage extends StatefulWidget {
  const RankedPage({super.key});

  @override
  State<RankedPage> createState() => _RankedPageState();
}

class _RankedPageState extends State<RankedPage> {
  final int _selectedIndex = 2;

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    Widget page;
    switch (index) {
      case 0:
        page = const RandomPage(title: "Random Wordle");
        break;
      case 1:
        page = const DailyPage(title: "Daily Wordle");
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
      appBar: buildAppBar(context, "Ranked"),
      body: Container(),
      bottomNavigationBar: buildBottomNavigationBar(
        context,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
