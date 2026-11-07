import 'package:thepadel/dataLayer/dataSource/dataSourceUtente.dart';
import 'package:thepadel/domainLayer/enetity/utente.dart';
import 'package:thepadel/domainLayer/enetity/voceClassifica.dart';
import 'package:thepadel/domainLayer/repositoryInterface/UtenteRepo.dart';

//deve occuparsi di gestire i vari data source per ogni concetto (ad esempio nel login deve pure chiamare la funzione per salvare l utente nel db) e poi restituire le entity 
class UtenteRepoImpl implements UtenteRepo{

  final DataSourceUtente dsUtente;

  UtenteRepoImpl({required this.dsUtente});
  
  @override
  Future<Utente> login(String telefono, String password) async {
    return dsUtente.login(telefono, password);
  }

  @override
  Future<void> logout() {
    return dsUtente.logout();
  }

  @override
  Future<void> eliminaAccount() {
    return dsUtente.eliminaAccount();
  }

  @override
  Future<int> registrazione(String nome, String cognome, String telefono, DateTime dataNascita, String password) {
    return dsUtente.registrazione(nome, cognome, telefono, dataNascita, password);
  }

  @override
  Future<List<VoceClassifica>> getClassifica() {
    return dsUtente.getClassifica();
  }
  
}