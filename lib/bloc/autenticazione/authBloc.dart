//colui che si occupa di emettere stati in seguito ad eventi 
//esiste un bloc generico per tutti gli eventi e gli stati di autenticazione
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/autenticazione/authevent.dart';
import 'package:thepadel/bloc/autenticazione/authState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/utente.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';
import 'package:thepadel/useCase/authUseCase.dart';


class AuthBloc extends Bloc<AuthEvent, AuthState> {
  //i vari use case 
  final LoginUseCase loginUseCase;
  final RegistrazioneUseCase registrazioneUseCase;

  //costruttire
  AuthBloc({required this.loginUseCase, required this.registrazioneUseCase}) : super(AuthInitial()) {//dichiaro lo stato iniziale 
    on<LoginRichiesto>(_onLoginRichiesto); //registra una funzione che verra eseguita ogni qualvolta qualcuno fara add di un oggetto del Tipo tipizzato
    on<RegistrazioneRichiesta>(_onRegistrazioneRichiesta);
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

  Future<void> _onRegistrazioneRichiesta(RegistrazioneRichiesta evento, Emitter<AuthState> emit) async
  {
    emit(AuthLoading());
    try{
      int res = await registrazioneUseCase.call(evento.nome, evento.cognome, evento.telefono, evento.dataNascita, evento.pw);
      emit(RegistrazioneSuccess());
    }on PwMancante catch (e){
      emit(AuthErrore(messaggio: e.message));
    } on FormatoTelefonoNonValido catch(e) {
        emit(AuthErrore(messaggio: e.message));
    } on NomeMancante catch (e) {
        emit(AuthErrore(messaggio : e.message));
    } on CognomeMancante catch(e) {
      emit(AuthErrore(messaggio : e.message));
    } on DataNascitaMancante catch (e) {
        emit(AuthErrore(messaggio : e.message));
    } on TelefonoDuplicatoException catch(e) {
      emit(AuthErrore(messaggio : e.messaggio));
    } on DataNonValida catch (e) {
        emit(AuthErrore(messaggio : e.messaggio));
    } on ErroreGenericoServer catch(e){
      emit(AuthErrore(messaggio : e.messaggio));
    }
  }

}
