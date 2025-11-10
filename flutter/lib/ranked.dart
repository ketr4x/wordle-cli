import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'connectivity.dart';
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
    final List<String> resultList = c.resultMessage?.split('\n') ?? <String>[];
    return Scaffold(
      appBar: buildAppBar(context, widget.title),
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: c.handleKeyEvent,
        child: GestureDetector(
          onTap: () {
            _focusNode.requestFocus();
          },
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
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        for (final resultMessage in resultList)
                          Text(
                            resultMessage,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: Theme.of(context).colorScheme.primary),
                          ),
                      ],
                    ),
                  ),
                ),
              if (c.errorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    c.errorMessage!,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ),
                if (c.errorMessage == 'Language pack invalid.' || c.errorMessage == 'File does not exist.') ...[
                  Builder(
                    builder: (context) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        showAdaptiveDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Invalid language pack'),
                            content: Text('The local language pack differs from the server one. Download it or change the server.'),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ConnectivityPage())).then((_) {
                                      widget.controller.refresh();
                                  });
                                },
                                child: const Text('Download')
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK')
                              )
                            ],
                          )
                        );
                      });
                      return const SizedBox.shrink();
                    }
                  )
                ] else ...[
                  Builder(
                    builder: (context) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        showErrorToast(c.errorMessage!);
                      });
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ],
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