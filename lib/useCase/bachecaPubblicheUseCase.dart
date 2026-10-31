import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/partitaPubblica.dart';
import 'package:thepadel/repositoryImpl/partitaRepoImpl.dart';

class PartitePubblicheUseCase {

  final PartitaRepoImpl repo;

  PartitePubblicheUseCase({required this.repo});

  Future<List<PartitaPubblica>> call()
  {
    return repo.getPartitePubbliche();
  }
}

class EntraInPartitaUseCase {

  final PartitaRepoImpl repo;

  EntraInPartitaUseCase({required this.repo});

  Future<DettaglioPartita> call(int idPartita)
  {
    return repo.entraInPartita(idPartita);
  }
}
