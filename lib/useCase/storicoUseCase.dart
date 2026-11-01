import 'package:thepadel/domainLayer/enetity/partitaStorico.dart';
import 'package:thepadel/repositoryImpl/partitaRepoImpl.dart';

class StoricoUseCase {

  final PartitaRepoImpl repo;

  StoricoUseCase({required this.repo});

  Future<List<PartitaStorico>> call()
  {
    return repo.getStorico();
  }
}
