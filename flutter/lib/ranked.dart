import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'utils.dart';
import 'ranked_controller.dart';

class WordleGameView extends StatefulWidget {
  final String title;
  final RankedWordleController controller;

  const WordleGameView({super.key, required this.title, required this.controller});

  @override
  State<WordleGameView> createState() => _WordleGameViewState();
}

class _WordleGameViewState extends State<WordleGameView> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    widget.controller.ensureInitialized();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      appBar: buildAppBar(context, widget.title),
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: c.handleKeyEvent,
        child: GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: Column(
            children: [
              Expanded(
                child: buildGame(
                  guesses: c.guesses,
                  currentGuess: c.currentGuess,
                  answer: c.answer,
                  letterStatuses: c.letterStatuses,
                  keyboardLayout: c.keyboardLayout,
                  onLetterTap: c.gameOver ? (_) {} : c.onLetterTap,
                  onEnterTap: c.gameOver ? () {} : c.onEnterTap,
                  onBackspaceTap: c.gameOver ? () {} : c.onBackspaceTap,
                  elapsed: c.elapsed,
                  onNewGame: c.restartGame,
                  context: context,
                  mode: GameMode.ranked,
                  gameOver: c.gameOver,
                  formattedGuesses: c.formattedGuesses,
                ),
              ),
              if (c.resultMessage != null)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    c.resultMessage!,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              if (c.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    c.errorMessage!,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ),
              if (c.loading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNavigationBar(
        context,
        currentIndex: 2,
      ),
    );
  }
}

class RankedPage extends StatelessWidget {
  const RankedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WordleGameView(
      title: "Ranked Wordle",
      controller: RankedWordleController(),
    );
  }
}