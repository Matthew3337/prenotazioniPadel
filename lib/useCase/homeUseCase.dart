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

//gli slot di oggi di tutti i campi, liberi e occupati, senza quelli gia iniziati:
//il server li segna come disponibili ma poi rifiuterebbe la prenotazione
class SlotOggiUseCase{

  final CampoRepoImpl repo;

  SlotOggiUseCase({required this.repo});

  Future<List<SlotOrario>> call(DateTime adesso) async
  {
    final campi = await repo.getListaCampi();
    final slots = await repo.getListaOrariSlotCampiAll(adesso);

    List<SlotOrario> slotOggi = [];
    for(final campo in campi)
    {
      List<SlotOrario> slotDelCampo = [];
      for(final slot in slots)
      {
        if(slot.idCampo == campo.id && !slot.inizioEffettivo(adesso, campo.oraApertura).isBefore(adesso))
        {
          slotDelCampo.add(slot);
        }
      }
      //il repository ordina per testo dell'ora, ma uno slot dopo mezzanotte va in fondo e non in cima
      slotDelCampo.sort((a, b) => a.inizioEffettivo(adesso, campo.oraApertura).compareTo(b.inizioEffettivo(adesso, campo.oraApertura)));
      slotOggi.addAll(slotDelCampo);
    }
    return slotOggi;
  }
}
