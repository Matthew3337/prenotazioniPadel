import 'package:thepadel/domainLayer/enetity/prenotazione.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';
import 'package:thepadel/repositoryImpl/campoRepoImpl.dart';
import 'package:thepadel/repositoryImpl/prenotazioneRepoImpl.dart';

class ProssimaPartitaUseCase {

  final PrenotazioneRepoImpl repo;

  ProssimaPartitaUseCase({required this.repo});

   Future<Prenotazione?> call()
   {
      return repo.getProssimaPartita();
   }
}

class SlotDisponibiliUseCase{

  final CampoRepoImpl repo;

  SlotDisponibiliUseCase({required this.repo});

  Future<List<SlotOrario>> call(DateTime data)
  {
    return repo.getListaOrariSlotCampiAll(data);
  }
}