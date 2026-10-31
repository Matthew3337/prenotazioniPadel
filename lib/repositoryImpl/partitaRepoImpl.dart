import 'package:thepadel/dataLayer/dataSource/dataSourcePartita.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/repositoryInterface/partitaRepo.dart';

class PartitaRepoImpl implements PartitaRepo {

  final DataSourcePartita dsPartita;

  PartitaRepoImpl({required this.dsPartita});

  @override
  Future<DettaglioPartita> getDettaglioPartita(int idPartita) {
    return dsPartita.getDettaglioPartita(idPartita);
  }

}
