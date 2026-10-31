import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/repositoryImpl/partitaRepoImpl.dart';

class DettaglioPartitaUseCase {

  final PartitaRepoImpl repo;

  DettaglioPartitaUseCase({required this.repo});

  Future<DettaglioPartita> call(int idPartita)
  {
    return repo.getDettaglioPartita(idPartita);
  }
}
