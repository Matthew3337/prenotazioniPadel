import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/utente.dart';
import 'package:thepadel/repositoryImpl/utenteRepoImpl.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

class LoginUseCase {
  final UtenteRepoImpl repo;
  LoginUseCase({required this.repo});

  Future<Utente> call(String telefono, String password) {
    if (telefono.length <= 9) {
      throw FormatoTelefonoNonValido();
    }  
    if(password.isEmpty)
    {
      throw PwMancante();
    }
    return repo.login(telefono, password);
  }
}

class RegistrazioneUseCase {
  
  final UtenteRepoImpl repo;
  RegistrazioneUseCase({required this.repo});

  Future<int> call(String nome, String cognome, String telefono, DateTime dataNascita, String password){

    if(nome.isEmpty)
    {
      throw NomeMancante();
    } 
    if(cognome.isEmpty)
    {
      throw CognomeMancante();
    }
    if(dataNascita.toString().isEmpty)
    {
      throw DataNascitaMancante();
    }
     if (telefono.length <= 9) {
      throw FormatoTelefonoNonValido();
    }  
    if(password.isEmpty)
    {
      throw PwMancante();
    }
    return repo.registrazione(nome, cognome, telefono, dataNascita, password);
  }

}