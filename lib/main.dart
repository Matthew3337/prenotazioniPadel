import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/ui/home.dart';
import 'package:thepadel/ui/homeAdmin.dart';
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
      if(sl<SharedPreferences>().getBool("isAdmin") == true)
      {
        home = const HomeAdminPage();
      }
      else
      {
        home = const HomePage();
      }
    }
    else 
    {
      home = const LoginPage();
    }
    return MaterialApp(
      title: 'ThePadel',
      //l'app e solo in italiano: senza questi il date picker sarebbe in inglese
      locale: const Locale('it'),
      supportedLocales: const [Locale('it')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        fontFamily: 'SourceSans3',
        scaffoldBackgroundColor: Colori.sfondo,
        colorScheme: ColorScheme.fromSeed(seedColor: Colori.primario),
      ),
      home:  home,
    );
  }
}
