import 'package:thepadel/domainLayer/enetity/utente.dart';
import 'package:thepadel/repositoryImpl/utenteRepoImpl.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

class LoginUseCase {
  final UtenteRepoImpl repo;
  LoginUseCase({required this.repo});

  Future<Utente> call(String telefono, String password) {
    if (telefono.length <= 9) {
      throw FormatoTelefonoNonValido();
    } else if(password.isEmpty)
    {
      throw PwMancante();
    }
    return repo.login(telefono, password);
  }
}