import 'package:flutter/material.dart';

class Campo {
  //attributi 
  final int id;
  final String nome;
  final bool alCoperto;
  final TimeOfDay oraApertura;
  final TimeOfDay oraChiusura;

  //metodi 
  //costruttore 
  Campo({required this.id, required this.nome, required this.alCoperto, required this.oraApertura, required this.oraChiusura});

}