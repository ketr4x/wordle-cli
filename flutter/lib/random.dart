import 'package:flutter/material.dart';
import 'universal_game.dart';

class RandomPage extends StatelessWidget {
  final String title;
  const RandomPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return GamePage(title: title, mode: GameMode.random);
  }
}