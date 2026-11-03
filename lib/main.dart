import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/ui/home.dart';
import 'package:thepadel/ui/login.dart';
import 'package:thepadel/ui/stileApp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  init(); //injecto le dipendenze 
  await sl.allReady();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Widget home;
    if(sl<SharedPreferences>().getBool("isLogged") ?? false )
    {
      home = const HomePage();
    }
    else 
    {
      home = const LoginPage();
    }
    return MaterialApp(
      title: 'ThePadel',
      theme: ThemeData(
        fontFamily: 'SourceSans3',
        scaffoldBackgroundColor: Colori.sfondo,
        colorScheme: ColorScheme.fromSeed(seedColor: Colori.primario),
      ),
      home:  home,
    );
  }
}
