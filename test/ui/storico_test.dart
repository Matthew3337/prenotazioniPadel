import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaBloc.dart';
import 'package:thepadel/bloc/storico/storicoBloc.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/partitaStorico.dart';
import 'package:thepadel/domainLayer/enetity/risultatoPartita.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';
import 'package:thepadel/ui/dettaglioPartita.dart';
import 'package:thepadel/ui/stileApp.dart';
import 'package:thepadel/ui/storico.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';
import 'package:thepadel/useCase/storicoUseCase.dart';

import '../fake/fakePartitaRepo.dart';
import '../fake/fakePreferenze.dart';
import '../fake/temaDiTest.dart';

void main()
{
  setUpAll(caricaFontDellApp);

  late FakePartitaRepo repo;

  setUp(() async
  {
    await sl.reset();
    await registraPreferenzeDiTest();
    repo = FakePartitaRepo();
    sl.registerFactory<StoricoBloc>(() => StoricoBloc(storicoUseCase: StoricoUseCase(repo: repo)));
    //serve per l'apertura del dettaglio dal tocco su una card
    sl.registerFactory<DettaglioPartitaBloc>(() => DettaglioPartitaBloc(dettaglioPartitaUseCase: DettaglioPartitaUseCase(repo: repo), eliminaPartitaUseCase: EliminaPartitaUseCase(repo: repo), esciDaPartitaUseCase: EsciDaPartitaUseCase(repo: repo), confermaPartitaUseCase: ConfermaPartitaUseCase(repo: repo), cambiaTipoUseCase: CambiaTipoUseCase(repo: repo)));
  });

  tearDown(() async
  {
    await sl.reset();
  });

  Future<void> apriPagina(WidgetTester tester) async
  {
    //schermo da telefono (390x844)
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const StoricoPage()));
    await tester.pumpAndSettle();
  }

  DateTime giornoPassato()
  {
    final oggi = DateTime.now();
    return DateTime(oggi.year, oggi.month, oggi.day - 3);
  }

  //partita iniziata 3 ore fa e finita un'ora fa: il risultato si puo ancora registrare.
  //Se la fine cade dopo mezzanotte la data resta quella dell'inizio, come la manda il server
  final DateTime inizioRecente = DateTime.now().subtract(const Duration(hours: 3));
  final DateTime fineRecente = DateTime.now().subtract(const Duration(hours: 1));
  final DateTime giornoRecente = DateTime(inizioRecente.year, inizioRecente.month, inizioRecente.day);

  PartitaStorico partitaRecente({int id = 10, String nomeCampo = "Campo Centrale", String stato = "giocata"})
  {
    return partitaStoricoDiTest(
      id: id,
      nomeCampo: nomeCampo,
      stato: stato,
      dataPartita: giornoRecente,
      oraInizio: TimeOfDay.fromDateTime(inizioRecente),
      oraFine: TimeOfDay.fromDateTime(fineRecente),
    );
  }

  testWidgets("mostra la riga con data, orario e campo; nessuna partita e In programma", (tester) async
  {
    final data = giornoPassato();
    repo.partiteStorico = [partitaStoricoDiTest(dataPartita: data, risultato: risultatoDiTest(), stato: "giocata")];
    await apriPagina(tester);

    expect(repo.chiamateStorico, 1);
    expect(find.text("Storico partite"), findsOneWidget);
    expect(find.text(conMaiuscola(dataEstesa(data))), findsOneWidget);
    expect(find.text("18:30 - 20:00 · Campo Centrale"), findsOneWidget);
    expect(find.text("In programma"), findsNothing);
    expect(find.text("Non hai ancora partite nello storico"), findsNothing);
    expect(find.textContaining("Manca il risultato"), findsNothing);
  });

  testWidgets("la voce Storico della barra e attiva: toccarla non cambia pagina", (tester) async
  {
    await apriPagina(tester);

    await tester.tap(find.text("Storico"));
    await tester.pumpAndSettle();

    expect(repo.chiamateStorico, 1);
    expect(find.byType(StoricoPage), findsOneWidget);
  });

  testWidgets("giocata senza risultato entro le 24 ore: pillola Senza risultato e invito a registrarlo", (tester) async
  {
    repo.partiteStorico = [partitaRecente(stato: "giocata")];
    await apriPagina(tester);

    expect(find.text("Senza risultato"), findsOneWidget);
    expect(find.text("Risultato non registrato"), findsNothing);
    expect(find.text("Manca il risultato di ${nomeGiorno(giornoRecente)}"), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "Registra risultato"), findsOneWidget);
  });

  testWidgets("confermata senza risultato: manca il risultato; creata senza risultato: niente da registrare", (tester) async
  {
    repo.partiteStorico = [
      partitaRecente(id: 10, nomeCampo: "Campo Uno", stato: "confermata"),
      partitaRecente(id: 11, nomeCampo: "Campo Due", stato: "creata"),
    ];
    await apriPagina(tester);

    expect(find.text("Senza risultato"), findsOneWidget);
    expect(find.text("In programma"), findsNothing);
    expect(find.textContaining("Manca il risultato"), findsOneWidget);
  });

  testWidgets("con piu partite senza risultato ne propone una sola", (tester) async
  {
    repo.partiteStorico = [
      partitaRecente(id: 10, stato: "giocata"),
      partitaRecente(id: 11, stato: "giocata"),
    ];
    await apriPagina(tester);

    expect(find.text("Senza risultato"), findsNWidgets(2));
    expect(find.textContaining("Manca il risultato"), findsOneWidget);
  });

  testWidgets("Registra risultato apre il dettaglio della partita", (tester) async
  {
    repo.partiteStorico = [partitaRecente(id: 12, stato: "giocata")];
    await apriPagina(tester);

    await tester.tap(find.text("Registra risultato"));
    await tester.pumpAndSettle();

    expect(find.byType(DettaglioPartitaPage), findsOneWidget);
    expect(repo.idRicevuto, 12);
  });

  testWidgets("termine scaduto: pillola Risultato non registrato, nessun invito a registrarlo", (tester) async
  {
    repo.partiteStorico = [
      partitaStoricoDiTest(id: 10, stato: "giocata", dataPartita: giornoPassato()),
      partitaStoricoDiTest(id: 11, stato: "confermata", dataPartita: giornoPassato()),
    ];
    await apriPagina(tester);

    expect(find.text("Risultato non registrato"), findsNWidgets(2));
    expect(find.text("Senza risultato"), findsNothing);
    expect(find.textContaining("Manca il risultato"), findsNothing);
    expect(find.text("Registra risultato"), findsNothing);
  });

  testWidgets("partita creata e mai giocata col termine scaduto: niente pillola Risultato non registrato", (tester) async
  {
    repo.partiteStorico = [partitaStoricoDiTest(stato: "creata", dataPartita: giornoPassato())];
    await apriPagina(tester);

    expect(find.text("Risultato non registrato"), findsNothing);
    expect(find.textContaining("Manca il risultato"), findsNothing);
  });

  testWidgets("partita finita dopo mezzanotte: il termine parte dalla fine del giorno dopo", (tester) async
  {
    //23:00 - 00:30 di ieri finisce oggi alle 00:30: il termine e domani alle 00:30, quindi non e scaduto.
    //Se la fine fosse contata su ieri il termine sarebbe gia passato
    final oggi = DateTime.now();
    final ieri = DateTime(oggi.year, oggi.month, oggi.day - 1);
    repo.partiteStorico = [
      partitaStoricoDiTest(stato: "giocata", dataPartita: ieri, oraInizio: const TimeOfDay(hour: 23, minute: 0), oraFine: const TimeOfDay(hour: 0, minute: 30)),
    ];
    await apriPagina(tester);

    expect(find.text("Risultato non registrato"), findsNothing);
    //prima delle 00:30 la partita non e ancora finita e non c'e niente da registrare
    if(oggi.isAfter(DateTime(oggi.year, oggi.month, oggi.day, 0, 30)))
    {
      expect(find.text("Senza risultato"), findsOneWidget);
      expect(find.text("Manca il risultato di ${nomeGiorno(ieri)}"), findsOneWidget);
    }
  });

  testWidgets("risultato con squadraUtente 1: set nel verso del server e pillola Vinta con i punti", (tester) async
  {
    repo.partiteStorico = [partitaStoricoDiTest(stato: "giocata", risultato: risultatoDiTest())];
    await apriPagina(tester);

    expect(find.text("6-4 3-6 6-2"), findsOneWidget);
    expect(find.text("Vinta · +12 pt"), findsOneWidget);
    expect(find.textContaining("Manca il risultato"), findsNothing);
  });

  testWidgets("con squadraUtente 2 i set sono girati dal punto di vista dell'utente", (tester) async
  {
    repo.partiteStorico = [
      partitaStoricoDiTest(stato: "giocata", risultato: risultatoDiTest(squadraUtente: 2, esito: "PERSA", puntiAssegnati: null)),
    ];
    await apriPagina(tester);

    expect(find.text("4-6 6-3 2-6"), findsOneWidget);
    expect(find.text("Persa"), findsOneWidget);
  });

  testWidgets("partita persa con punti negativi: Persa e -7 pt", (tester) async
  {
    final risultato = RisultatoPartita(
      set: [SetPartita(squadra1: 6, squadra2: 1), SetPartita(squadra1: 6, squadra2: 3)],
      squadraUtente: 2,
      esito: "PERSA",
      puntiAssegnati: -7,
    );
    repo.partiteStorico = [partitaStoricoDiTest(stato: "giocata", risultato: risultato)];
    await apriPagina(tester);

    expect(find.text("1-6 3-6"), findsOneWidget);
    expect(find.text("Persa · -7 pt"), findsOneWidget);
    expect(find.textContaining("Vinta"), findsNothing);
  });

  testWidgets("con esito null mostra solo i set", (tester) async
  {
    repo.partiteStorico = [
      partitaStoricoDiTest(stato: "giocata", risultato: risultatoDiTest(squadraUtente: null, esito: null, puntiAssegnati: null)),
    ];
    await apriPagina(tester);

    expect(find.text("6-4 3-6 6-2"), findsOneWidget);
    expect(find.text("Giocata"), findsOneWidget);
    expect(find.textContaining("Vinta"), findsNothing);
    expect(find.textContaining("Persa"), findsNothing);
    expect(find.textContaining(" pt"), findsNothing);
  });

  testWidgets("con partite con risultato il titolo resta Storico partite, senza bilancio", (tester) async
  {
    repo.partiteStorico = [
      partitaStoricoDiTest(id: 10, stato: "giocata", risultato: risultatoDiTest()),
      partitaStoricoDiTest(id: 11, stato: "giocata", risultato: risultatoDiTest()),
      partitaStoricoDiTest(id: 12, stato: "giocata", risultato: risultatoDiTest(esito: "PERSA")),
    ];
    await apriPagina(tester);

    expect(find.text("Storico partite"), findsOneWidget);
    expect(find.text("2 vinte, 1 persa"), findsNothing);
    expect(find.textContaining("partite con risultato"), findsNothing);
  });

  testWidgets("storico vuoto: mostra il messaggio e le due strade, nessuna riga", (tester) async
  {
    repo.partiteStorico = [];
    await apriPagina(tester);

    expect(find.text("Non hai ancora partite nello storico"), findsOneWidget);
    expect(find.text("Prenota un campo"), findsOneWidget);
    expect(find.text("Trova una partita"), findsOneWidget);
    expect(find.textContaining("Campo Centrale"), findsNothing);
  });

  testWidgets("errore di caricamento: messaggio e Riprova rifa la richiesta", (tester) async
  {
    repo.erroreStorico = ErroreGenericoServer();
    await apriPagina(tester);

    expect(find.text(ErroreGenericoServer().messaggio), findsOneWidget);
    expect(find.text("Riprova"), findsOneWidget);

    repo.erroreStorico = null;
    await tester.tap(find.text("Riprova"));
    await tester.pumpAndSettle();

    expect(repo.chiamateStorico, 2);
    expect(find.textContaining("Campo Centrale"), findsOneWidget);
  });

  testWidgets("il tocco su una riga apre il dettaglio e al ritorno lo storico si ricarica", (tester) async
  {
    repo.partiteStorico = [partitaStoricoDiTest(id: 10)];
    await apriPagina(tester);

    await tester.tap(find.textContaining("Campo Centrale"));
    await tester.pumpAndSettle();

    expect(find.byType(DettaglioPartitaPage), findsOneWidget);
    expect(find.text("Dettaglio partita"), findsOneWidget);
    expect(repo.idRicevuto, 10);

    repo.partiteStorico = [];
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.byType(DettaglioPartitaPage), findsNothing);
    expect(repo.chiamateStorico, 2);
    expect(find.text("Non hai ancora partite nello storico"), findsOneWidget);
  });
}
