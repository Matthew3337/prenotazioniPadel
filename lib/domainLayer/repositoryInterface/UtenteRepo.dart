
import 'package:thepadel/domainLayer/enetity/utente.dart';
import 'package:thepadel/domainLayer/enetity/voceClassifica.dart';

abstract class UtenteRepo {

  Future<Utente> login(String telefono, String Password);

  Future<int> registrazione(String nome, String cognome, String telefono, DateTime dataNascita, String password);

  int logout();

  Future<List<VoceClassifica>> getClassifica();

}