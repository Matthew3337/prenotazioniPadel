import 'package:thepadel/domainLayer/enetity/partitaStorico.dart';
import 'package:thepadel/repositoryImpl/partitaRepoImpl.dart';

//le partite dell'utente non ancora finite: lo storico invece ha solo quelle gia giocate
class MiePartiteUseCase {

  final PartitaRepoImpl repo;

  MiePartiteUseCase({required this.repo});

  Future<List<PartitaStorico>> call()
  {
    return repo.getMiePartite();
  }
}
