import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/utenteInvitabile.dart';
import 'package:thepadel/repositoryImpl/partitaRepoImpl.dart';

class InvitabiliUseCase {

  final PartitaRepoImpl repo;

  InvitabiliUseCase({required this.repo});

  //con cerca vuoto il server restituisce tutti gli utenti invitabili
  Future<List<UtenteInvitabile>> call(int idPartita, String cerca)
  {
    return repo.getInvitabili(idPartita, cerca);
  }
}

//gli utenti che si possono invitare in una partita che non esiste ancora, cioe mentre la si prenota
class UtentiInvitabiliUseCase {

  final PartitaRepoImpl repo;

  UtentiInvitabiliUseCase({required this.repo});

  //con cerca vuoto il server restituisce tutti gli utenti invitabili
  Future<List<UtenteInvitabile>> call(String cerca)
  {
    return repo.getUtentiInvitabili(cerca);
  }
}

class InvitaUtenteUseCase {

  final PartitaRepoImpl repo;

  InvitaUtenteUseCase({required this.repo});

  Future<DettaglioPartita> call(int idPartita, String telefono)
  {
    return repo.invitaUtente(idPartita, telefono);
  }
}
