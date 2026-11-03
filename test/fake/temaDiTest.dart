import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/ui/stileApp.dart';

//senza questi font i test userebbero quello di Flutter, con ogni lettera larga quanto alta:
//le righe andrebbero in overflow anche quando sul telefono ci stanno
Future<void> caricaFontDellApp() async
{
  TestWidgetsFlutterBinding.ensureInitialized();

  final sourceSans = FontLoader('SourceSans3');
  sourceSans.addFont(rootBundle.load('assets/fonts/SourceSans3-Regular.ttf'));
  sourceSans.addFont(rootBundle.load('assets/fonts/SourceSans3-SemiBold.ttf'));
  sourceSans.addFont(rootBundle.load('assets/fonts/SourceSans3-Bold.ttf'));
  await sourceSans.load();

  final bitter = FontLoader('Bitter');
  bitter.addFont(rootBundle.load('assets/fonts/Bitter-Medium.ttf'));
  bitter.addFont(rootBundle.load('assets/fonts/Bitter-SemiBold.ttf'));
  bitter.addFont(rootBundle.load('assets/fonts/Bitter-Bold.ttf'));
  await bitter.load();
}

//lo stesso tema di main.dart
ThemeData temaDiTest()
{
  return ThemeData(
    fontFamily: 'SourceSans3',
    scaffoldBackgroundColor: Colori.sfondo,
    colorScheme: ColorScheme.fromSeed(seedColor: Colori.primario),
  );
}
