import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';
import 'package:thepadel/repositoryImpl/partitaRepoImpl.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

//la regola sul punteggio di un set, usata anche da ModificaRisultatoUseCase.
//Chi vince ha 6 game e l'altra squadra al massimo 4, oppure il set finisce 7-5 o 7-6
bool setValido(SetPartita s)
{
  int vincente = s.squadra1;
  int perdente = s.squadra2;
  if(s.squadra2 > s.squadra1)
  {
    vincente = s.squadra2;
    perdente = s.squadra1;
  }

  if(perdente < 0)
  {
    return false;
  }
  if(vincente == 6 && perdente <= 4)
  {
    return true;
  }
  if(vincente == 7 && (perdente == 5 || perdente == 6))
  {
    return true;
  }
  return false;
}

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
      if(!setValido(s))
      {
        throw SetNonValido();
      }
    }

    return repo.registraRisultato(idPartita, squadra1, squadra2, set);
  }
}
