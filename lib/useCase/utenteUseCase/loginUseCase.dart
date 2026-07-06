import 'package:thepadel/domainLayer/enetity/utente.dart';
import 'package:thepadel/domainLayer/repositoryInterface/UtenteRepo.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

class LoginUseCase {
  final UtenteRepo repo;
  LoginUseCase({required this.repo});

  Future<Utente> call(String telefono, String password) {
    if (telefono.length <= 9) {
      throw FormatoTelefonoNonValido();
    }
    return repo.login(telefono, password);
  }
}