
import 'package:thepadel/domainLayer/enetity/utente.dart';

abstract class UtenteRepo {

  Future<Utente> login(String telefono, String Password);

  Future<int> registrazione(String nome, String cognome, String telefono, DateTime dataNascita, String password);

  int logout();

}