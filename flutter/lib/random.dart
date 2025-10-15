import 'package:flutter/material.dart';
import 'package:wordle/universal_game.dart';

class RandomPage extends StatelessWidget {
  const RandomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WordleGameView(
      title: "Random Wordle",
      controller: WordleGameController(mode: GameMode.random),
    );
  }
}