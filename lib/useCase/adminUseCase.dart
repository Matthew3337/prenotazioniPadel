import 'package:thepadel/domainLayer/enetity/avvisoAdmin.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/partiteCampoAdmin.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';
import 'package:thepadel/domainLayer/enetity/utenteAdmin.dart';
import 'package:thepadel/repositoryImpl/adminRepoImpl.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';
import 'package:thepadel/useCase/registraRisultatoUseCase.dart';

class PartiteGiornoUseCase {

  final AdminRepoImpl repo;

  PartiteGiornoUseCase({required this.repo});

  Future<List<PartiteCampoAdmin>> call(DateTime data)
  {
    return repo.getPartiteDelGiorno(data);
  }
}

class BachecaAvvisiUseCase {

  final AdminRepoImpl repo;

  BachecaAvvisiUseCase({required this.repo});

  Future<List<AvvisoAdmin>> call()
  {
    return repo.getAvvisi();
  }
}

class UtentiAdminUseCase {

  final AdminRepoImpl repo;

  UtentiAdminUseCase({required this.repo});

  //con cerca vuoto il server restituisce tutti gli utenti non admin
  Future<List<UtenteAdmin>> call(String cerca)
  {
    return repo.getUtenti(cerca);
  }
}

class CambiaLivelloUseCase {

  final AdminRepoImpl repo;

  CambiaLivelloUseCase({required this.repo});

  Future<UtenteAdmin> call(String telefono, double livello)
  {
    //moltiplicando per 2 i livelli con passo 0,5 diventano numeri interi
    double doppio = livello * 2;
    if(livello < 0 || livello > 5 || doppio != doppio.roundToDouble())
    {
      throw LivelloNonValido();
    }

    return repo.cambiaLivello(telefono, livello);
  }
}

class ModificaPartecipantiUseCase {

  final AdminRepoImpl repo;

  ModificaPartecipantiUseCase({required this.repo});

  //telefoni e l'elenco completo degli utenti dopo la modifica: duplicati e posti del campo li controlla il server
  Future<DettaglioPartita> call(int idPartita, List<String> telefoni)
  {
    if(telefoni.isEmpty)
    {
      throw PartecipantiMancanti();
    }

    if(telefoni.length > 4)
    {
      throw TroppiPartecipanti();
    }

    return repo.modificaPartecipanti(idPartita, telefoni);
  }
}

class ModificaRisultatoUseCase {

  final AdminRepoImpl repo;

  ModificaRisultatoUseCase({required this.repo});

  //stessi controlli di RegistraRisultatoUseCase: anche qui la regola sui set vinti la decide il server
  Future<DettaglioPartita> call(int idPartita, List<int> squadra1, List<int> squadra2, List<SetPartita> set)
  {
    if(squadra1.length != 2 || squadra2.length != 2)
    {
      throw SquadraIncompleta();
    }

    //se un posto e ripetuto (nella stessa squadra o in tutte e due) l'insieme ne contiene meno di 4
    Set<int> posti = {};
    posti.addAll(squadra1);
    posti.addAll(squadra2);
    if(posti.length != 4)
    {
      throw GiocatoriRipetuti();
    }

    if(set.length != 2 && set.length != 3)
    {
      throw NumeroSetNonValido();
    }

    for (SetPartita s in set)
    {
      if(!setValido(s))
      {
        throw SetNonValido();
      }
    }

    return repo.modificaRisultato(idPartita, squadra1, squadra2, set);
  }
}

class ModificaStatoUseCase {

  final AdminRepoImpl repo;

  ModificaStatoUseCase({required this.repo});

  Future<DettaglioPartita> call(int idPartita, String stato)
  {
    return repo.modificaStato(idPartita, stato);
  }
}

class AnnullaPartitaUseCase {

  final AdminRepoImpl repo;

  AnnullaPartitaUseCase({required this.repo});

  Future<DettaglioPartita> call(int idPartita)
  {
    return repo.annullaPartita(idPartita);
  }
}
