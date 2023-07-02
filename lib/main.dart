import 'package:flutter/material.dart';
import 'package:molang/models/db.dart';
import 'package:molang/pages/home_page.dart';
import 'package:system_theme/system_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemTheme.fallbackColor = Colors.deepPurple;
  await SystemTheme.accentColor.load();
  await DB.instance.init();

  runApp(const MoLang());
}

class MoLang extends StatelessWidget {
  const MoLang({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoLang',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: SystemTheme.accentColor.accent, brightness: SystemTheme.isDarkMode ? Brightness.dark : Brightness.light),
        brightness: SystemTheme.isDarkMode ? Brightness.dark : Brightness.light,
        useMaterial3: true,
      ),
      home: const Home(),
    );
  }
}
