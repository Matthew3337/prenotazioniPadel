import 'package:flutter/material.dart';
import 'package:thepadel/dataLayer/model/slotOrarioModel.dart';
import 'package:thepadel/domainLayer/enetity/campo.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';

abstract class CampoRepo {
  
  Future<List<SlotOrario>> getListaOrariSlotCampiAll(DateTime data);

  Future<List<SlotOrario>> getListaOrariSlotByCampoId(int id, DateTime data);

  Future<List<Campo>> getListaCampi();

  Future<Campo> creaCampo(String nome, bool alCoperto, TimeOfDay oraApertura, TimeOfDay oraChiusura);

  Future<Campo> modificaCampo(int id, String nome, bool alCoperto, TimeOfDay oraApertura, TimeOfDay oraChiusura);

  Future<void> eliminaCampo(int id);
}