import 'package:thepadel/dataLayer/dataSource/dataSourceCampo.dart';
import 'package:thepadel/domainLayer/enetity/campo.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';
import 'package:thepadel/domainLayer/repositoryInterface/campoRepo.dart';

class CampoRepoImpl implements CampoRepo{
  final DataSourceCampo dsCampo;

  CampoRepoImpl({required this.dsCampo});

  @override
  Future<List<SlotOrario>> getListaOrariSlotByCampoId(int id, DateTime data) {

    return dsCampo.getSlotByIdEData(id, data);

  }

  @override
  Future<List<Campo>> getListaCampi() {

    return dsCampo.getListaCampi();
   
  }

  @override
  Future<List<SlotOrario>> getListaOrariSlotCampiAll(DateTime data) async {

    final campi = await dsCampo.getListaCampi();

    final listeSlot = await Future.wait(
      campi.map((c) => dsCampo.getSlotByIdEData(c.id, data)),
    );

    final tuttiGliSlot = listeSlot.expand((slot) => slot).toList();

    tuttiGliSlot.sort((a, b) =>
        (a.oraInizio).compareTo(b.oraInizio));

    return tuttiGliSlot;    
  }
  
}