import 'package:thepadel/domainLayer/enetity/voceClassifica.dart';
import 'package:thepadel/repositoryImpl/utenteRepoImpl.dart';

class ClassificaUseCase {

  final UtenteRepoImpl repo;

  ClassificaUseCase({required this.repo});

  Future<List<VoceClassifica>> call()
  {
    return repo.getClassifica();
  }
}
