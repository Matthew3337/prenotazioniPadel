// auth_state.dart
import 'package:thepadel/domainLayer/enetity/utente.dart';

abstract class AuthState {}

//il campo del form a cui si riferisce un errore, nessuno se l'errore e generale
enum CampoErroreAuth { nome, cognome, dataNascita, telefono, password, nessuno }

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

// Success differenziati per operazione
class LoginSuccess extends AuthState {
  final Utente utente;
  LoginSuccess({required  this.utente});
}

class RegistrazioneSuccess extends AuthState {
}

class LogoutSuccess extends AuthState {}

// Errore, generico va bene qui perché porta solo il messaggio e il campo a cui si riferisce
class AuthErrore extends AuthState {
  final String messaggio;
  final CampoErroreAuth campo;
  AuthErrore({required this.messaggio, this.campo = CampoErroreAuth.nessuno});
}