import 'package:flutter/material.dart';
import 'universal_game.dart';

class RandomPage extends StatelessWidget {
  const RandomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GamePage(title: "Random Wordle", mode: GameMode.random);
  }
}