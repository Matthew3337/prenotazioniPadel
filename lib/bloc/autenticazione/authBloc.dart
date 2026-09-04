//colui che si occupa di emettere stati in seguito ad eventi 
//esiste un bloc generico per tutti gli eventi e gli stati di autenticazione
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/autenticazione/authevent.dart';
import 'package:thepadel/bloc/autenticazione/authState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/utente.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';
import 'package:thepadel/useCase/utenteUseCase/loginUseCase.dart';


class AuthBloc extends Bloc<AuthEvent, AuthState> {
  //i vari use case 
  final LoginUseCase loginUseCase;
  AuthBloc({required this.loginUseCase}) : super(AuthInitial()) {//dichiaro lo stato iniziale 
    on<LoginRichiesto>(_onLoginRichiesto); //registra una funzione che verra eseguita ogni qualvolta qualcuno fara add di un oggetto del Tipo tipizzato
  }


Future<void> _onLoginRichiesto(LoginRichiesto evento, Emitter<AuthState> emit) async //evento contiene l istanza specifica dell evento con tutti i dati, emit serve a pubblicare uno stato 
{
  //emetto il loading poi chiamo lo usecase e poi in base al risultato emetto lo stato successivo
  emit(AuthLoading());

  try{
    final utenteRetrived = await loginUseCase.call(evento.telefono, evento.password);
     emit(LoginSuccess(utente: utenteRetrived));
  }on PwMancante catch (e){
    emit(AuthErrore(messaggio: e.message));
  } on FormatoTelefonoNonValido catch(e) {
      emit(AuthErrore(messaggio: e.message));
  } on TelefonoDuplicatoException catch (e) {
      emit(AuthErrore(messaggio : e.messaggio));
  } on TelOPasswordErrata catch(e) {
    emit(AuthErrore(messaggio : e.messaggio));
  } on ErroreGenericoServer catch (e) {
      emit(AuthErrore(messaggio : e.messaggio));
  } 
}
}
