import 'package:flutter/material.dart';
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

  @override
  Future<Campo> creaCampo(String nome, bool alCoperto, TimeOfDay oraApertura, TimeOfDay oraChiusura) {

    return dsCampo.creaCampo(nome, alCoperto, oraApertura, oraChiusura);

  }

  @override
  Future<Campo> modificaCampo(int id, String nome, bool alCoperto, TimeOfDay oraApertura, TimeOfDay oraChiusura) {

    return dsCampo.modificaCampo(id, nome, alCoperto, oraApertura, oraChiusura);

  }

  @override
  Future<void> eliminaCampo(int id) {

    return dsCampo.eliminaCampo(id);

  }
  
}