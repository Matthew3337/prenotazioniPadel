import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/ui/stileApp.dart';

void main()
{
  group("testi", ()
  {
    test("conMaiuscola alza solo la prima lettera e regge il testo vuoto", ()
    {
      expect(conMaiuscola("oggi"), "Oggi");
      expect(conMaiuscola(""), "");
    });

    test("nomeGiorno, giornoEMese e dataEstesa", ()
    {
      //il 2 novembre 2026 e un lunedi
      final data = DateTime(2026, 11, 2);

      expect(nomeGiorno(data), "lunedì");
      expect(nomeGiorno(DateTime(2026, 11, 8)), "domenica");
      expect(giornoEMese(data), "2 novembre");
      expect(dataEstesa(data), "lunedì 2 novembre");
    });

    test("giornoRelativo dice oggi, domani oppure il nome del giorno", ()
    {
      final adesso = DateTime.now();

      expect(giornoRelativo(adesso), "oggi");
      expect(giornoRelativo(DateTime(adesso.year, adesso.month, adesso.day + 1, 23, 59)), "domani");
      final fraTre = DateTime(adesso.year, adesso.month, adesso.day + 3);
      expect(giornoRelativo(fraTre), nomeGiorno(fraTre));
    });

    test("formattaOra aggiunge gli zeri", ()
    {
      expect(formattaOra(const TimeOfDay(hour: 8, minute: 5)), "08:05");
      expect(formattaOra(const TimeOfDay(hour: 18, minute: 30)), "18:30");
    });

    test("oraBreve toglie i secondi solo se ci sono", ()
    {
      expect(oraBreve("18:30:00"), "18:30");
      expect(oraBreve("18:30"), "18:30");
    });

    test("unisciNomi usa la virgola, la e, e la ed davanti alla E", ()
    {
      expect(unisciNomi([]), "");
      expect(unisciNomi(["Sara"]), "Sara");
      expect(unisciNomi(["Sara", "Luca"]), "Sara e Luca");
      expect(unisciNomi(["Sara", "Luca", "Elena"]), "Sara, Luca ed Elena");
    });
  });

  group("Responsive", ()
  {
    testWidgets("i font scalano sulla larghezza 390, entro i limiti", (tester) async
    {
      await tester.pumpWidget(MaterialApp(home: const Scaffold(body: Text("contenuto"))));

      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pump();
      final standard = Responsive(tester.element(find.text("contenuto")));
      expect(standard.textScale, 1.0);
      expect(standard.font(10), 10);
      expect(standard.isTablet, false);
      expect(standard.maxContentWidth, double.infinity);

      tester.view.physicalSize = const Size(320, 800);
      await tester.pump();
      expect(Responsive(tester.element(find.text("contenuto"))).textScale, 0.85);

      tester.view.physicalSize = const Size(800, 800);
      await tester.pump();
      final tablet = Responsive(tester.element(find.text("contenuto")));
      expect(tablet.textScale, 1.1);
      expect(tablet.isTablet, true);
      expect(tablet.maxContentWidth, 640);
    });
  });

  group("widget comuni", ()
  {
    Future<void> mostra(WidgetTester tester, Widget figlio) async
    {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: figlio))));
    }

    testWidgets("BottonePieno: attivo, spento senza azione, in caricamento mostra lo spinner", (tester) async
    {
      int tocchi = 0;
      await mostra(tester, BottonePieno(testo: "Vai", onPressed: () { tocchi++; }));
      await tester.tap(find.text("Vai"));
      expect(tocchi, 1);

      await mostra(tester, const BottonePieno(testo: "Vai", onPressed: null));
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNull);

      await mostra(tester, BottonePieno(testo: "Vai", inCaricamento: true, onPressed: () { tocchi++; }));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text("Vai"), findsNothing);
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNull);
    });

    testWidgets("CardErrore: titolo, testo opzionale e Riprova", (tester) async
    {
      int riprove = 0;
      await mostra(tester, CardErrore(titolo: "Titolo", testo: "Spiegazione", onRiprova: () { riprove++; }));

      expect(find.text("Titolo"), findsOneWidget);
      expect(find.text("Spiegazione"), findsOneWidget);
      await tester.tap(find.text("Riprova"));
      expect(riprove, 1);

      await mostra(tester, CardErrore(titolo: "Titolo", onRiprova: () {}));
      expect(find.text("Spiegazione"), findsNothing);
    });

    testWidgets("RiquadroMessaggio mostra il testo e l'azione se c'e", (tester) async
    {
      await mostra(tester, const RiquadroMessaggio(testo: "Messaggio", azione: Text("Azione")));

      expect(find.text("Messaggio"), findsOneWidget);
      expect(find.text("Azione"), findsOneWidget);
    });

    testWidgets("mostraSnackBar mostra il testo in una SnackBar floating", (tester) async
    {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (context) => TextButton(onPressed: () { mostraSnackBar(context, "Fatto"); }, child: const Text("apri"))))));

      await tester.tap(find.text("apri"));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(SnackBar, "Fatto"), findsOneWidget);
      expect(tester.widget<SnackBar>(find.byType(SnackBar)).behavior, SnackBarBehavior.floating);
    });

    testWidgets("TestataIndietro torna indietro, o fa l'azione passata", (tester) async
    {
      int tocchi = 0;
      await mostra(tester, TestataIndietro(titolo: "Titolo", onIndietro: () { tocchi++; }));

      expect(find.text("Titolo"), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      expect(tocchi, 1);
    });
  });

  test("testoPostiLiberi: nessuno, singolare e plurale", ()
  {
    expect(testoPostiLiberi(0), "Nessun posto libero");
    expect(testoPostiLiberi(1), "1 posto libero");
    expect(testoPostiLiberi(3), "3 posti liberi");
  });

  group("PillolaStato", ()
  {
    final attesi = {"creata": "Creata", "confermata": "Confermata", "annullata": "Annullata", "giocata": "Giocata"};

    attesi.forEach((stato, testo)
    {
      testWidgets("$stato mostra $testo", (tester) async
      {
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: PillolaStato(stato: stato))));

        expect(find.text(testo), findsOneWidget);
      });
    });
  });

  testWidgets("CampoRicerca mostra etichetta e suggerimento e passa il testo scritto", (tester) async
  {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final scritti = <String>[];

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CampoRicerca(controller: controller, onChanged: scritti.add))));

    expect(find.text("Cerca per nome"), findsOneWidget);
    expect(find.text("Nome o cognome"), findsOneWidget);

    await tester.enterText(find.byType(TextField), "mar");

    expect(scritti, ["mar"]);
    expect(controller.text, "mar");
  });
}
