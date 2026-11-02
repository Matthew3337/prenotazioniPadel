import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';
import 'package:thepadel/repositoryImpl/partitaRepoImpl.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

class RegistraRisultatoUseCase {

  final PartitaRepoImpl repo;

  RegistraRisultatoUseCase({required this.repo});

  //qui controllo solo gli errori evidenti del form, la regola "una squadra vince esattamente 2 set" la decide il server
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
      if(s.squadra1 < 0 || s.squadra1 > 6 || s.squadra2 < 0 || s.squadra2 > 6 || s.squadra1 == s.squadra2)
      {
        throw SetNonValido();
      }
    }

    return repo.registraRisultato(idPartita, squadra1, squadra2, set);
  }
}
