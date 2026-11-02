import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/dataLayer/dataSource/dataSourceUtente.dart';
import 'package:thepadel/domainLayer/enetity/voceClassifica.dart';
import 'package:thepadel/repositoryImpl/utenteRepoImpl.dart';

import 'fakePrenotazioneRepo.dart';

VoceClassifica voceDiTest({int posizione = 1, String telefono = "3335550001", String nome = "Luca", String cognome = "Bianchi", int punteggio = 12, bool utenteCorrente = false})
{
  return VoceClassifica(posizione: posizione, telefono: telefono, nome: nome, cognome: cognome, punteggio: punteggio, utenteCorrente: utenteCorrente);
}

//repository finto: estende quello vero (lo use case dipende dalla classe concreta)
//ma non passa mai dal data source, restituisce la classifica o lancia l'errore impostati dal test
class FakeUtenteRepo extends UtenteRepoImpl
{
  //attributi
  List<VoceClassifica> voci = [];
  Exception? errore;
  int chiamate = 0;

  //metodi
  FakeUtenteRepo() : super(dsUtente: DataSourceUtente(c: Client(c: MockClient((_) async => http.Response('', 500))), elencoUrl: urlDiTest()));

  @override
  Future<List<VoceClassifica>> getClassifica() async
  {
    chiamate++;

    if(errore != null)
    {
      throw errore!;
    }
    return voci;
  }
}
