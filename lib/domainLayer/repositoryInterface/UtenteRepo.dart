import 'package:thepadel/dataLayer/model/utenteModel.dart';

abstract class UtenteRepo {

  UtenteModel login(String telefono, String Password);

  int registrazione(UtenteModel utente);

  int logout();

}