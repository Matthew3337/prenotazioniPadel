// auth_event.dart
abstract class AuthEvent {}

class LoginRichiesto extends AuthEvent {
  final String telefono;
  final String password;
  LoginRichiesto({required this.telefono, required this.password});
}

class RegistrazioneRichiesta extends AuthEvent {
  //parametri della form di registrazione
  final String nome;
  final String cognome;
  final String telefono;
  final DateTime dataNascita;
  final String pw;
  RegistrazioneRichiesta({required this.cognome, required this.dataNascita, required this.nome, required this.telefono, required this.pw});
}

class LogoutRichiesto extends AuthEvent {}