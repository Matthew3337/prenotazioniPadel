import 'package:thepadel/domainLayer/enetity/campo.dart';
import 'package:thepadel/repositoryImpl/campoRepoImpl.dart';

class ListaCampiUseCase {

  final CampoRepoImpl repo;

  ListaCampiUseCase({required this.repo});

  Future<List<Campo>> call()
  {
    return repo.getListaCampi();
  }
}
