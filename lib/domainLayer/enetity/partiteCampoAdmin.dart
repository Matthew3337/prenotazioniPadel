import 'package:thepadel/domainLayer/enetity/partitaAdmin.dart';

//le partite di un giorno su un campo: il server manda un elemento per ogni campo, anche se non ha partite
class PartiteCampoAdmin {
  //attributi
  final int idCampo;
  final String nomeCampo;
  final List<PartitaAdmin> partite;

  PartiteCampoAdmin({required this.idCampo, required this.nomeCampo, required this.partite});
}
