import 'package:flutter/material.dart';
import 'utils.dart';

class RankedPage extends StatelessWidget {
  const RankedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Ranked'),
      body: const Center(
        child: Text('Ranked Mode Coming Soon!'),
      ),
      bottomNavigationBar: buildBottomNavigationBar(context, currentIndex: 3),
    );
  }
}