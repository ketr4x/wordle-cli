import 'package:flutter/material.dart';
import 'settings.dart';

AppBar buildAppBar(BuildContext context, widget) {
  return AppBar(
    backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    title: Text(widget.title),
    actions: [
      IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        },
      ),
    ],
  );
}

BottomNavigationBar buildBottomNavigationBar(
    BuildContext context, {
    required int currentIndex,
    required ValueChanged<int> onTap,
    }
    )
{
  return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.shuffle),
          label: 'Random',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Daily',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.star),
          label: 'Ranked',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.leaderboard),
          label: 'Leaderboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.query_stats),
          label: 'Stats',
        ),
      ]
  );
}

class WordleLetterBoxes extends StatelessWidget {
  final String letters;
  final double boxSize;
  final TextStyle textStyle;
  final Color boxColor;
  final Color borderColor;

  const WordleLetterBoxes({
    super.key,
    required this.letters,
    this.boxSize = 48,
    this.textStyle = const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    this.boxColor = Colors.white,
    this.borderColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        String letter = index < letters.length ? letters[index] : '';
        return Container(
          width: boxSize,
          height: boxSize,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: boxColor,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            letter.toUpperCase(),
            style: textStyle,
          ),
        );
      }),
    );
  }
}