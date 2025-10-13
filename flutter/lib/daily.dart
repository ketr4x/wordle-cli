import 'package:flutter/material.dart';
import 'universal_game.dart';

class DailyPage extends StatelessWidget {
  final String title;
  const DailyPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return GamePage(title: title, mode: GameMode.daily);
  }
}