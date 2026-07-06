// auth_state.dart
import 'package:thepadel/domainLayer/enetity/utente.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

// Success differenziati per operazione
class LoginSuccess extends AuthState {
  final Utente utente;
  LoginSuccess({required  this.utente});
}

class RegistrazioneSuccess extends AuthState {
  final Utente utente;
  RegistrazioneSuccess(this.utente);
}

class LogoutSuccess extends AuthState {}

// Errore, generico va bene qui perché porta sempre solo un messaggio
class AuthErrore extends AuthState {
  final String messaggio;
  AuthErrore({required this.messaggio});
}