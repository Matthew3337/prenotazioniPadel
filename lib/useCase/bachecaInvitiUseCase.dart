import 'package:thepadel/domainLayer/enetity/partitaInvito.dart';
import 'package:thepadel/repositoryImpl/partitaRepoImpl.dart';

class BachecaInvitiUseCase {

  final PartitaRepoImpl repo;

  BachecaInvitiUseCase({required this.repo});

  Future<List<PartitaInvito>> call()
  {
    return repo.getInviti();
  }
}
