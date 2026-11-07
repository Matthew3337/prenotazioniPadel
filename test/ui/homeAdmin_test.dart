import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/ui/bachecaAvvisi.dart';
import 'package:thepadel/ui/bottoneEsci.dart';
import 'package:thepadel/ui/gestioneCampi.dart';
import 'package:thepadel/ui/gestioneLivelli.dart';
import 'package:thepadel/ui/homeAdmin.dart';
import 'package:thepadel/ui/nuovaPartitaAdmin.dart';
import 'package:thepadel/ui/partiteGiorno.dart';
import 'package:thepadel/ui/stileApp.dart';

import '../fake/blocDiTest.dart';
import '../fake/fakeAdminRepo.dart';
import '../fake/fakeCampoRepo.dart';
import '../fake/fakePartitaRepo.dart';
import '../fake/fakePreferenze.dart';
import '../fake/fakePrenotazioneRepo.dart';
import '../fake/fakeUtenteRepo.dart';
import '../fake/temaDiTest.dart';

void main()
{
  setUpAll(caricaFontDellApp);

  late FakeAdminRepo repo;
  late FakeCampoRepo repoCampo;

  final adesso = DateTime.now();
  final oggi = DateTime(adesso.year, adesso.month, adesso.day);
  //domani nessuno slot e gia iniziato, a qualunque ora girino i test
  final domani = DateTime(adesso.year, adesso.month, adesso.day + 1);

  setUp(() async
  {
    await sl.reset();
    await registraPreferenzeDiTest();
    repo = FakeAdminRepo();
    repoCampo = FakeCampoRepo();
    registraBlocDiTest(repoPartita: FakePartitaRepo(), repoCampo: repoCampo, repoPrenotazione: FakePrenotazioneRepo(), repoUtente: FakeUtenteRepo(), repoAdmin: repo);
  });

  tearDown(() async
  {
    await sl.reset();
  });

  Future<void> apriPagina(WidgetTester tester, {Size schermo = const Size(390, 844), bool aspetta = true}) async
  {
    tester.view.physicalSize = schermo * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const HomeAdminPage()));
    if(aspetta)
    {
      await tester.pumpAndSettle();
    }
  }

  void chiudiPaginaInCima(WidgetTester tester)
  {
    final NavigatorState navigator = tester.state(find.byType(Navigator).first);
    navigator.pop();
  }

  testWidgets("mostra le tre voci e il bottone Esci", (tester) async
  {
    await apriPagina(tester);

    expect(find.text("Area amministratore"), findsOneWidget);
    expect(find.text("Partite del giorno"), findsOneWidget);
    expect(find.text("Bacheca avvisi"), findsOneWidget);
    expect(find.text("Gestione livelli"), findsOneWidget);
    expect(find.byType(BottoneEsci), findsOneWidget);
  });

  testWidgets("su un telefono piccolo non va in overflow", (tester) async
  {
    await apriPagina(tester, schermo: const Size(320, 568));

    expect(tester.takeException(), isNull);
  });

  group("saluto", ()
  {
    testWidgets("col nome salvato al login", (tester) async
    {
      await sl<SharedPreferences>().setString("nome", "Paola");
      await apriPagina(tester);

      expect(find.text("Ciao, Paola"), findsOneWidget);
    });

    testWidgets("senza nome salvato resta Ciao", (tester) async
    {
      await apriPagina(tester);

      expect(find.text("Ciao"), findsOneWidget);
    });
  });

  group("numero di avvisi", ()
  {
    testWidgets("nessun avviso", (tester) async
    {
      await apriPagina(tester);

      expect(find.text("Nessun avviso aperto"), findsOneWidget);
      expect(repo.chiamateAvvisi, 1);
    });

    testWidgets("un avviso, al singolare", (tester) async
    {
      repo.avvisi = [avvisoDiTest()];
      await apriPagina(tester);

      expect(find.text("1 avviso aperto"), findsOneWidget);
    });

    testWidgets("piu avvisi, al plurale", (tester) async
    {
      repo.avvisi = [avvisoDiTest(id: 1), avvisoDiTest(id: 2), avvisoDiTest(id: 3)];
      await apriPagina(tester);

      expect(find.text("3 avvisi aperti"), findsOneWidget);
    });

    testWidgets("durante il caricamento c'e la barra grigia", (tester) async
    {
      repo.attesaAvvisi = Completer<void>();
      await apriPagina(tester, aspetta: false);
      await tester.pump();

      expect(find.byType(BarraGrigia), findsOneWidget);
      expect(find.text("Nessun avviso aperto"), findsNothing);

      repo.attesaAvvisi!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(BarraGrigia), findsNothing);
    });

    testWidgets("in errore lo dice e la voce resta apribile", (tester) async
    {
      repo.erroreAvvisi = ErroreGenericoServer();
      await apriPagina(tester);

      expect(find.text("Numero di avvisi non disponibile"), findsOneWidget);

      await tester.tap(find.text("Bacheca avvisi"));
      await tester.pumpAndSettle();

      expect(find.byType(BachecaAvvisiPage), findsOneWidget);
    });
  });

  group("navigazione", ()
  {
    testWidgets("Partite del giorno apre la sua pagina", (tester) async
    {
      await apriPagina(tester);

      await tester.tap(find.text("Partite del giorno"));
      await tester.pumpAndSettle();

      expect(find.byType(PartiteGiornoPage), findsOneWidget);
    });

    testWidgets("Bacheca avvisi apre la sua pagina", (tester) async
    {
      await apriPagina(tester);

      await tester.tap(find.text("Bacheca avvisi"));
      await tester.pumpAndSettle();

      expect(find.byType(BachecaAvvisiPage), findsOneWidget);
    });

    testWidgets("Gestione livelli apre la sua pagina", (tester) async
    {
      await apriPagina(tester);

      await tester.tap(find.text("Gestione livelli"));
      await tester.pumpAndSettle();

      expect(find.byType(GestioneLivelliPage), findsOneWidget);
    });

    testWidgets("al ritorno da una pagina il numero di avvisi viene richiesto di nuovo", (tester) async
    {
      repo.avvisi = [avvisoDiTest(id: 1), avvisoDiTest(id: 2)];
      await apriPagina(tester);
      expect(find.text("2 avvisi aperti"), findsOneWidget);

      await tester.tap(find.text("Gestione livelli"));
      await tester.pumpAndSettle();

      repo.avvisi = [avvisoDiTest(id: 1)];
      chiudiPaginaInCima(tester);
      await tester.pumpAndSettle();

      expect(repo.chiamateAvvisi, 2);
      expect(find.text("1 avviso aperto"), findsOneWidget);
    });
  });

  group("voci nuove", ()
  {
    testWidgets("Nuova partita apre la sua pagina", (tester) async
    {
      await apriPagina(tester);

      await tester.ensureVisible(find.text("Nuova partita"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Nuova partita"));
      await tester.pumpAndSettle();

      expect(find.byType(NuovaPartitaAdminPage), findsOneWidget);
    });

    testWidgets("Gestione campi apre la sua pagina", (tester) async
    {
      await apriPagina(tester);

      await tester.ensureVisible(find.text("Gestione campi"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Gestione campi"));
      await tester.pumpAndSettle();

      expect(find.byType(GestioneCampiPage), findsOneWidget);
    });
  });

  group("livello giocatori campo", ()
  {
    double? valoreSelettore(WidgetTester tester)
    {
      return tester.widget<DropdownButton<double>>(find.byType(DropdownButton<double>)).value;
    }

    Future<void> scegliLivello(WidgetTester tester, String livello) async
    {
      await tester.ensureVisible(find.byType(DropdownButton<double>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<double>));
      await tester.pumpAndSettle();
      //la voce compare anche nel bottone chiuso: l'ultima e quella del menu aperto
      await tester.tap(find.text(livello).last);
      await tester.pump();
    }

    testWidgets("mostra il livello del server e offre le voci da 0 a 5 con passo 0,5", (tester) async
    {
      repo.livelloCampo = 2.5;
      await apriPagina(tester);

      expect(find.text("Livello giocatori campo"), findsOneWidget);
      expect(valoreSelettore(tester), 2.5);

      final List<double?> voci = [];
      for(final voce in tester.widget<DropdownButton<double>>(find.byType(DropdownButton<double>)).items!)
      {
        voci.add(voce.value);
      }
      expect(voci, [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0]);
    });

    testWidgets("scegliere una voce salva subito, con lo spinner durante il salvataggio", (tester) async
    {
      await apriPagina(tester);
      final attesa = Completer<void>();
      repo.attesaSalvaLivelloCampo = attesa;

      await scegliLivello(tester, "3.5");
      await tester.pump();

      expect(repo.livelliCampoRicevuti, [3.5]);
      expect(find.byType(DropdownButton<double>), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      attesa.complete();
      await tester.pumpAndSettle();

      expect(valoreSelettore(tester), 3.5);
    });

    testWidgets("scegliere il livello gia attivo non chiama il server", (tester) async
    {
      await apriPagina(tester);

      await scegliLivello(tester, "2.0");
      await tester.pumpAndSettle();

      expect(repo.livelliCampoRicevuti, isEmpty);
    });

    testWidgets("se il salvataggio fallisce il selettore torna indietro e compare il messaggio", (tester) async
    {
      await apriPagina(tester);
      repo.erroreSalvaLivelloCampo = OperazioneRifiutata(messaggio: "Il livello deve essere tra 0 e 5 con passo 0,5");

      await scegliLivello(tester, "3.5");
      await tester.pumpAndSettle();

      expect(valoreSelettore(tester), 2.0);
      expect(find.text("Il livello deve essere tra 0 e 5 con passo 0,5"), findsOneWidget);
    });

    testWidgets("se il primo caricamento fallisce c'e Riprova, senza SnackBar", (tester) async
    {
      repo.erroreLivelloCampo = ErroreGenericoServer();
      await apriPagina(tester);

      expect(find.text("Livello non disponibile"), findsOneWidget);
      expect(find.byType(DropdownButton<double>), findsNothing);
      expect(find.byType(SnackBar), findsNothing);

      repo.erroreLivelloCampo = null;
      await tester.ensureVisible(find.text("Riprova"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Riprova"));
      await tester.pumpAndSettle();

      expect(repo.chiamateLivelloCampo, 2);
      expect(valoreSelettore(tester), 2.0);
    });
  });

  group("slot liberi", ()
  {
    Future<void> scegliGiorno(WidgetTester tester, DateTime giorno) async
    {
      final Finder casella = find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == dataEstesa(giorno));
      await tester.ensureVisible(casella);
      await tester.pumpAndSettle();
      await tester.tap(casella);
      await tester.pumpAndSettle();
    }

    testWidgets("mostra per campo solo gli slot liberi, non quelli occupati", (tester) async
    {
      repoCampo.campi = [campoDiTest(id: 3, nome: "Campo Centrale"), campoDiTest(id: 4, nome: "Campo Due")];
      repoCampo.slots = [
        slotCampoDiTest(idCampo: 3, oraInizio: "18:30:00", oraFine: "20:00:00"),
        slotCampoDiTest(idCampo: 3, oraInizio: "20:00:00", oraFine: "21:30:00", disponibile: false),
        slotCampoDiTest(idCampo: 4, nomeCampo: "Campo Due", oraInizio: "10:00:00", oraFine: "11:30:00", disponibile: false),
      ];
      await apriPagina(tester);
      await scegliGiorno(tester, domani);

      expect(find.text("Slot liberi"), findsOneWidget);
      expect(find.text("Campo Centrale"), findsOneWidget);
      expect(find.text("Campo Due"), findsOneWidget);
      expect(find.text("18:30"), findsOneWidget);
      expect(find.text("20:00"), findsNothing);
      expect(find.text("10:00"), findsNothing);
      //il campo pieno resta in elenco con la scritta
      expect(find.text("Nessuno slot libero"), findsOneWidget);
    });

    testWidgets("gli slot gia iniziati di oggi non compaiono, lo stesso orario domani si", (tester) async
    {
      //con l'apertura a mezzanotte lo slot delle 00:00 di oggi e sicuramente gia iniziato
      repoCampo.campi = [campoDiTest(oraApertura: const TimeOfDay(hour: 0, minute: 0))];
      repoCampo.slots = [slotCampoDiTest(oraInizio: "00:00:00", oraFine: "01:30:00")];
      await apriPagina(tester);

      expect(repoCampo.dateRicevute.first, oggi);
      expect(find.text("00:00"), findsNothing);
      expect(find.text("Nessuno slot libero"), findsOneWidget);

      await scegliGiorno(tester, domani);

      expect(repoCampo.dateRicevute.last, domani);
      expect(find.text("00:00"), findsOneWidget);
      expect(find.text("Nessuno slot libero"), findsNothing);
    });

    testWidgets("senza slot liberi lo dice", (tester) async
    {
      repoCampo.slots = [slotCampoDiTest(disponibile: false)];
      await apriPagina(tester);
      await scegliGiorno(tester, domani);

      expect(find.text("Nessuno slot libero"), findsOneWidget);
    });

    testWidgets("senza campi rimanda a Gestione campi", (tester) async
    {
      repoCampo.campi = [];
      await apriPagina(tester);

      expect(find.text("Non ci sono campi. Puoi aggiungerli da Gestione campi."), findsOneWidget);
    });

    testWidgets("durante il caricamento ci sono le righe grigie", (tester) async
    {
      repoCampo.attesePerData[oggi] = Completer();
      await apriPagina(tester, aspetta: false);
      await tester.pump();

      expect(find.byType(BarraGrigia), findsWidgets);
      expect(find.text("Nessuno slot libero"), findsNothing);

      repoCampo.attesePerData[oggi]!.complete([slotCampoDiTest(disponibile: false)]);
      await tester.pumpAndSettle();
      expect(find.text("Nessuno slot libero"), findsOneWidget);
    });

    testWidgets("in errore c'e il messaggio col giorno e Riprova ricarica", (tester) async
    {
      repoCampo.erroreSlot = ErroreGenericoServer();
      await apriPagina(tester);

      expect(find.text("Non siamo riusciti a caricare gli slot di ${nomeGiorno(oggi)}"), findsOneWidget);
      final int chiamatePrima = repoCampo.chiamateSlot;

      repoCampo.erroreSlot = null;
      repoCampo.slots = [slotCampoDiTest(disponibile: false)];
      await tester.ensureVisible(find.text("Riprova"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Riprova"));
      await tester.pumpAndSettle();

      expect(repoCampo.chiamateSlot, chiamatePrima + 1);
      expect(find.text("Riprova"), findsNothing);
      expect(find.text("Nessuno slot libero"), findsOneWidget);
    });

    testWidgets("il tocco su uno slot apre Nuova partita con giorno e slot gia scelti, al ritorno ricarica", (tester) async
    {
      await apriPagina(tester);
      await scegliGiorno(tester, domani);

      await tester.ensureVisible(find.text("18:30"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("18:30"));
      await tester.pumpAndSettle();

      final pagina = tester.widget<NuovaPartitaAdminPage>(find.byType(NuovaPartitaAdminPage));
      expect(pagina.giornoIniziale, domani);
      expect(pagina.slotIniziale!.idCampo, 3);
      expect(pagina.slotIniziale!.oraInizio, "18:30:00");
      expect(find.text("Campo Centrale, ${dataEstesa(domani)}, 18:30 - 20:00"), findsOneWidget);

      final int slotPrima = repoCampo.chiamateSlot;
      final int avvisiPrima = repo.chiamateAvvisi;
      chiudiPaginaInCima(tester);
      await tester.pumpAndSettle();

      expect(repoCampo.chiamateSlot, slotPrima + 1);
      expect(repoCampo.dateRicevute.last, domani);
      expect(repo.chiamateAvvisi, avvisiPrima + 1);
    });
  });
}
