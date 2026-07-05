
import 'package:thepadel/domainLayer/enetity/utente.dart';

abstract class UtenteRepo {

  Utente login(String telefono, String Password);

  int registrazione();

  int logout();

}