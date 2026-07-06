// auth_event.dart
abstract class AuthEvent {}

class LoginRichiesto extends AuthEvent {
  final String telefono;
  final String password;
  LoginRichiesto({required this.telefono, required this.password});
}

class RegistrazioneRichiesta extends AuthEvent {
  //parametri della form di registrazione
  RegistrazioneRichiesta();
}

class LogoutRichiesto extends AuthEvent {}