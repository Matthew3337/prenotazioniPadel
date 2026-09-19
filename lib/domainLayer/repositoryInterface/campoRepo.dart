import 'package:thepadel/dataLayer/model/slotOrarioModel.dart';
import 'package:thepadel/domainLayer/enetity/campo.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';

abstract class CampoRepo {
  
  Future<List<SlotOrario>> getListaOrariSlotCampiAll(DateTime data);

  Future<List<SlotOrario>> getListaOrariSlotByCampoId(int id, DateTime data);

  Future<List<Campo>> getListaCampi();
}