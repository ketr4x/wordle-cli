import 'package:flutter/material.dart';
import 'package:wordle/random.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:wordle/utils.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AdaptiveThemeMode? savedThemeMode;
  try {
    savedThemeMode = await AdaptiveTheme.getThemeMode();
  } catch (e) {
    savedThemeMode = AdaptiveThemeMode.light;
  }
  runApp(MyApp(savedThemeMode: savedThemeMode,));
}

class MyApp extends StatelessWidget {
  final AdaptiveThemeMode? savedThemeMode;
  const MyApp({super.key, this.savedThemeMode});

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      dark: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueAccent, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      initial: savedThemeMode ?? AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ConnectionStateProvider()),
          ChangeNotifierProvider(create: (_) => AccountStateProvider()),
        ],
        child: MaterialApp(
          title: 'Wordle',
          theme: theme,
          darkTheme: darkTheme,
          home: MyHomePage(title: 'Wordle'),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return RandomPage();
  }
}