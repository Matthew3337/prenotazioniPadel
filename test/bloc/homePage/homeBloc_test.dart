import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/homePage/homeBloc.dart';
import 'package:thepadel/bloc/homePage/homeEvent.dart';
import 'package:thepadel/bloc/homePage/homeState.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/dataLayer/dataSource/dataSourceCampo.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/voceClassifica.dart';
import 'package:thepadel/repositoryImpl/campoRepoImpl.dart';
import 'package:thepadel/useCase/classificaUseCase.dart';
import 'package:thepadel/useCase/homeUseCase.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../fake/fakePrenotazioneRepo.dart';
import '../../fake/fakeUtenteRepo.dart';

Matcher classificaLoading()
{
  return isA<HomeState>().having((s) => s.classifica, "classifica", isA<SectionLoading<VoceClassifica>>());
}

void main()
{
  late FakeUtenteRepo repo;
  late HomeBloc bloc;

  setUp(()
  {
    repo = FakeUtenteRepo();
    //le altre due sezioni qui non vengono richieste: i loro repository non sono mai chiamati
    final campi = CampoRepoImpl(dsCampo: DataSourceCampo(c: Client(c: MockClient((_) async => http.Response('', 500))), elencoUrl: urlDiTest()));
    bloc = HomeBloc(
      prossimaPartitaUseCase: ProssimaPartitaUseCase(repo: FakePrenotazioneRepo()),
      slotUseCase: SlotDisponibiliUseCase(repo: campi),
      classificaUseCase: ClassificaUseCase(repo: repo),
    );
  });

  tearDown(() async
  {
    await bloc.close();
  });

  test("lo stato iniziale ha la classifica in caricamento", ()
  {
    expect(bloc.state.classifica, isA<SectionLoading<VoceClassifica>>());
  });

  test("utente presente: Loading poi Success con la sua riga, anche se non e la prima", () async
  {
    repo.voci = [
      voceDiTest(posizione: 1, telefono: "1", punteggio: 9),
      voceDiTest(posizione: 2, telefono: "2", punteggio: 5, utenteCorrente: true),
      voceDiTest(posizione: 3, telefono: "3", punteggio: 1),
    ];
    bloc.add(const HomeClassificaRequested());

    await expectLater(bloc.stream, emitsInOrder([
      classificaLoading(),
      isA<HomeState>().having((s) => s.classifica, "classifica", isA<SectionSuccess<VoceClassifica>>()
        .having((c) => c.data.telefono, "telefono", "2")
        .having((c) => c.data.posizione, "posizione", 2)
        .having((c) => c.data.punteggio, "punteggio", 5)),
    ]));
  });

  test("utente assente (admin): Loading poi Empty", () async
  {
    repo.voci = [voceDiTest(telefono: "1"), voceDiTest(telefono: "2")];
    bloc.add(const HomeClassificaRequested());

    await expectLater(bloc.stream, emitsInOrder([
      classificaLoading(),
      isA<HomeState>().having((s) => s.classifica, "classifica", isA<SectionEmpty<VoceClassifica>>()),
    ]));
  });

  test("classifica vuota: Loading poi Empty", () async
  {
    repo.voci = [];
    bloc.add(const HomeClassificaRequested());

    await expectLater(bloc.stream, emitsInOrder([
      classificaLoading(),
      isA<HomeState>().having((s) => s.classifica, "classifica", isA<SectionEmpty<VoceClassifica>>()),
    ]));
  });

  test("errore: Loading poi Error col messaggio di ErroreGenericoServer", () async
  {
    repo.errore = ErroreGenericoServer();
    bloc.add(const HomeClassificaRequested());

    await expectLater(bloc.stream, emitsInOrder([
      classificaLoading(),
      isA<HomeState>().having((s) => s.classifica, "classifica", isA<SectionError<VoceClassifica>>()
        .having((c) => c.message, "message", ErroreGenericoServer().messaggio)),
    ]));
  });

  test("copyWith sulla classifica non tocca le altre sezioni", ()
  {
    final prima = HomeState.initial();

    final dopo = prima.copyWith(classifica: const SectionEmpty());

    expect(dopo.classifica, isA<SectionEmpty<VoceClassifica>>());
    expect(identical(dopo.prossimaPartita, prima.prossimaPartita), true);
    expect(identical(dopo.slotOggi, prima.slotOggi), true);
  });
}
