import 'package:flutter/material.dart';
import 'utils.dart';

class RandomPage extends StatefulWidget {
  const RandomPage({super.key, required this.title});
  final String title;

  @override
  State<RandomPage> createState() => _RandomPageState();
}

class _RandomPageState extends State<RandomPage> {
  int _selectedIndex = 0;

  String answer = 'apple'; // Example answer
  List<String> guesses = [];
  String currentGuess = '';

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, widget),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 25, 10, 8),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  WordleLetterBoxes(letters: ''),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: TextField(
                maxLength: 5,
                onChanged: (value) {
                  setState(() {
                    currentGuess = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Enter your guess',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
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