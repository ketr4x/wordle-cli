import 'package:flutter/material.dart';
import 'utils.dart';

class RankedPage extends StatelessWidget {
  const RankedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return buildBottomNavigationBar(context, currentIndex: 3);
  }
}