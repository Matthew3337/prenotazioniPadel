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

class EliminaPartitaUseCase {

  final PartitaRepoImpl repo;

  EliminaPartitaUseCase({required this.repo});

  Future<void> call(int idPartita)
  {
    return repo.eliminaPartita(idPartita);
  }
}

class EsciDaPartitaUseCase {

  final PartitaRepoImpl repo;

  EsciDaPartitaUseCase({required this.repo});

  Future<void> call(int idPartita)
  {
    return repo.esciDaPartita(idPartita);
  }
}

class ConfermaPartitaUseCase {

  final PartitaRepoImpl repo;

  ConfermaPartitaUseCase({required this.repo});

  Future<DettaglioPartita> call(int idPartita)
  {
    return repo.confermaPartita(idPartita);
  }
}
