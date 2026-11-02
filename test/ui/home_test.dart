import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:thepadel/bloc/classifica/classificaBloc.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaBloc.dart';
import 'package:thepadel/bloc/homePage/homeBloc.dart';
import 'package:thepadel/bloc/storico/storicoBloc.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/dataLayer/dataSource/dataSourceCampo.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/prenotazione.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';
import 'package:thepadel/repositoryImpl/campoRepoImpl.dart';
import 'package:thepadel/ui/classifica.dart';
import 'package:thepadel/ui/dettaglioPartita.dart';
import 'package:thepadel/ui/home.dart';
import 'package:thepadel/ui/storico.dart';
import 'package:thepadel/useCase/classificaUseCase.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';
import 'package:thepadel/useCase/homeUseCase.dart';
import 'package:thepadel/useCase/storicoUseCase.dart';

import '../fake/fakePartitaRepo.dart';
import '../fake/fakePrenotazioneRepo.dart';
import '../fake/fakeUtenteRepo.dart';

//la prossima partita e l'unica chiamata del repository vero che serve alla home
class FakeProssimaRepo extends FakePrenotazioneRepo
{
  //attributi
  Prenotazione? prossima;
  int chiamateProssima = 0;

  //metodi
  @override
  Future<Prenotazione?> getProssimaPartita() async
  {
    chiamateProssima++;
    return prossima;
  }
}

class FakeCampoRepo extends CampoRepoImpl
{
  //attributi
  int chiamateSlot = 0;

  //metodi
  FakeCampoRepo() : super(dsCampo: DataSourceCampo(c: Client(c: MockClient((_) async => http.Response('', 500))), elencoUrl: urlDiTest()));

  @override
  Future<List<SlotOrario>> getListaOrariSlotCampiAll(DateTime data) async
  {
    chiamateSlot++;
    return [slotDiTest()];
  }
}

void main()
{
  late FakeProssimaRepo repoProssima;
  late FakeCampoRepo repoCampo;
  late FakeUtenteRepo repoUtente;
  late FakePartitaRepo repoPartita;

  setUp(() async
  {
    await sl.reset();
    repoProssima = FakeProssimaRepo();
    repoCampo = FakeCampoRepo();
    repoUtente = FakeUtenteRepo();
    repoPartita = FakePartitaRepo();
    repoUtente.voci = [
      voceDiTest(posizione: 1, nome: "Anna", cognome: "Verdi", punteggio: 20),
      voceDiTest(posizione: 7, nome: "Mario", cognome: "Rossi", punteggio: 42, utenteCorrente: true),
    ];

    sl.registerFactory<HomeBloc>(() => HomeBloc(
      prossimaPartitaUseCase: ProssimaPartitaUseCase(repo: repoProssima),
      slotUseCase: SlotDisponibiliUseCase(repo: repoCampo),
      classificaUseCase: ClassificaUseCase(repo: repoUtente),
    ));
    sl.registerFactory<ClassificaBloc>(() => ClassificaBloc(classificaUseCase: ClassificaUseCase(repo: repoUtente)));
    sl.registerFactory<StoricoBloc>(() => StoricoBloc(storicoUseCase: StoricoUseCase(repo: repoPartita)));
    sl.registerFactory<DettaglioPartitaBloc>(() => DettaglioPartitaBloc(dettaglioPartitaUseCase: DettaglioPartitaUseCase(repo: repoPartita), eliminaPartitaUseCase: EliminaPartitaUseCase(repo: repoPartita), esciDaPartitaUseCase: EsciDaPartitaUseCase(repo: repoPartita), confermaPartitaUseCase: ConfermaPartitaUseCase(repo: repoPartita)));
  });

  tearDown(() async
  {
    await sl.reset();
  });

  Future<void> apriHome(WidgetTester tester) async
  {
    //schermo da telefono alto (390x1200): la card della classifica sta in fondo alla pagina
    tester.view.physicalSize = const Size(1170, 3600);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();
  }

  void chiudiPaginaInCima(WidgetTester tester)
  {
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pop();
  }

  void controllaChiamate(int attese)
  {
    expect(repoProssima.chiamateProssima, attese);
    expect(repoCampo.chiamateSlot, attese);
    expect(repoUtente.chiamate, attese);
  }

  group("card classifica", ()
  {
    testWidgets("mostra posizione e punteggio reali dell'utente corrente", (tester) async
    {
      await apriHome(tester);

      controllaChiamate(1);
      expect(find.text("La tua posizione"), findsOneWidget);
      expect(find.text("7"), findsOneWidget);
      expect(find.text("Punteggio: 42"), findsOneWidget);
      //i vecchi dati finti non devono piu comparire
      expect(find.text("Punteggio: 1240"), findsNothing);
      expect(find.text("Classifica non disponibile"), findsNothing);
    });

    testWidgets("SectionEmpty: l'admin vede Classifica non disponibile", (tester) async
    {
      repoUtente.voci = [voceDiTest(posizione: 1, nome: "Anna", cognome: "Verdi")];
      await apriHome(tester);

      expect(find.text("Classifica non disponibile"), findsOneWidget);
      expect(find.textContaining("Punteggio:"), findsNothing);
    });

    testWidgets("SectionError: messaggio e Riprova ricarica solo la classifica, senza aprire la pagina", (tester) async
    {
      repoUtente.errore = ErroreGenericoServer();
      await apriHome(tester);

      expect(find.text(ErroreGenericoServer().messaggio), findsOneWidget);
      expect(find.text("Riprova"), findsOneWidget);

      repoUtente.errore = null;
      await tester.tap(find.text("Riprova"));
      await tester.pumpAndSettle();

      expect(find.byType(ClassificaPage), findsNothing);
      expect(repoUtente.chiamate, 2);
      expect(repoProssima.chiamateProssima, 1);
      expect(repoCampo.chiamateSlot, 1);
      expect(find.text("Punteggio: 42"), findsOneWidget);
    });

    testWidgets("il tocco sulla card apre la classifica e al ritorno ricarica le tre sezioni", (tester) async
    {
      await apriHome(tester);

      await tester.tap(find.text("Classifica completa"));
      await tester.pumpAndSettle();
      expect(find.byType(ClassificaPage), findsOneWidget);
      expect(repoUtente.chiamate, 2); //quella della home e quella della pagina

      repoUtente.voci = [voceDiTest(posizione: 3, punteggio: 50, utenteCorrente: true)];
      chiudiPaginaInCima(tester);
      await tester.pumpAndSettle();

      expect(find.byType(ClassificaPage), findsNothing);
      expect(repoProssima.chiamateProssima, 2);
      expect(repoCampo.chiamateSlot, 2);
      expect(repoUtente.chiamate, 3);
      expect(find.text("Punteggio: 50"), findsOneWidget);
    });
  });

  group("barra di navigazione", ()
  {
    testWidgets("la voce Classifica apre la pagina", (tester) async
    {
      await apriHome(tester);

      await tester.tap(find.text("Classifica"));
      await tester.pumpAndSettle();

      expect(find.byType(ClassificaPage), findsOneWidget);
    });

    testWidgets("al ritorno dallo storico ricarica le tre sezioni", (tester) async
    {
      await apriHome(tester);

      await tester.tap(find.text("Storico"));
      await tester.pumpAndSettle();
      expect(find.byType(StoricoPage), findsOneWidget);

      chiudiPaginaInCima(tester);
      await tester.pumpAndSettle();

      controllaChiamate(2);
    });
  });

  group("ritorno dal dettaglio", ()
  {
    testWidgets("senza risultato (freccia indietro) ricarica comunque le tre sezioni", (tester) async
    {
      repoProssima.prossima = prenotazioneDiTest();
      await apriHome(tester);
      controllaChiamate(1);

      await tester.tap(find.text("Prossima partita"));
      await tester.pumpAndSettle();
      expect(find.byType(DettaglioPartitaPage), findsOneWidget);
      expect(repoPartita.idRicevuto, 10);

      //il punteggio cambia mentre si e nel dettaglio, come dopo un risultato registrato
      repoUtente.voci = [voceDiTest(posizione: 2, punteggio: 45, utenteCorrente: true)];
      chiudiPaginaInCima(tester);
      await tester.pumpAndSettle();

      expect(find.byType(DettaglioPartitaPage), findsNothing);
      controllaChiamate(2);
      expect(find.text("Punteggio: 45"), findsOneWidget);
    });
  });

  testWidgets("su un telefono stretto la riga degli slot non va in overflow", (tester) async
  {
    tester.view.physicalSize = const Size(960, 3600);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("Slot disponibili oggi"), findsOneWidget);
    expect(find.text("Vedi altri giorni"), findsOneWidget);
  });
}
