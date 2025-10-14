import 'package:flutter/material.dart';
import 'universal_game.dart';

class DailyPage extends StatelessWidget {
  const DailyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GamePage(title: "Daily Wordle", mode: GameMode.daily);
  }
}