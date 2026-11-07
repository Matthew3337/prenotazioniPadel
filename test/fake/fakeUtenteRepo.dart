import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/dataLayer/dataSource/dataSourceUtente.dart';
import 'package:thepadel/domainLayer/enetity/utente.dart';
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

  //login e registrazione: se l'errore e null l'operazione riesce
  Exception? erroreLogin;
  Completer<void>? attesaLogin; //se impostato la chiamata resta in sospeso finche il test non la completa
  int chiamateLogin = 0;
  Exception? erroreRegistrazione;
  Completer<void>? attesaRegistrazione;
  int chiamateRegistrazione = 0;

  //logout: se l'errore e null l'operazione riesce
  Exception? erroreLogout;
  Completer<void>? attesaLogout;
  int chiamateLogout = 0;

  //eliminazione dell'account: se l'errore e null l'operazione riesce
  Exception? erroreEliminaAccount;
  Completer<void>? attesaEliminaAccount;
  int chiamateEliminaAccount = 0;

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

  @override
  Future<Utente> login(String telefono, String password) async
  {
    chiamateLogin++;

    if(attesaLogin != null)
    {
      await attesaLogin!.future;
    }
    if(erroreLogin != null)
    {
      throw erroreLogin!;
    }
    return Utente(telefono: telefono, nome: "Mario", cognome: "Rossi", dataNascita: DateTime(1990, 1, 1), isAdmin: false, livello: 2.5);
  }

  @override
  Future<int> registrazione(String nome, String cognome, String telefono, DateTime dataNascita, String password) async
  {
    chiamateRegistrazione++;

    if(attesaRegistrazione != null)
    {
      await attesaRegistrazione!.future;
    }
    if(erroreRegistrazione != null)
    {
      throw erroreRegistrazione!;
    }
    return 201;
  }

  @override
  Future<void> logout() async
  {
    chiamateLogout++;

    if(attesaLogout != null)
    {
      await attesaLogout!.future;
    }
    if(erroreLogout != null)
    {
      throw erroreLogout!;
    }
  }

  @override
  Future<void> eliminaAccount() async
  {
    chiamateEliminaAccount++;

    if(attesaEliminaAccount != null)
    {
      await attesaEliminaAccount!.future;
    }
    if(erroreEliminaAccount != null)
    {
      throw erroreEliminaAccount!;
    }
  }
}
