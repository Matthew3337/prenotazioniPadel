import 'package:thepadel/dataLayer/dataSource/dataSourceUtente.dart';
import 'package:thepadel/domainLayer/enetity/utente.dart';
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
  int logout() {
    // TODO: implement logout
    throw UnimplementedError();
  }

  @override
  int registrazione() {
    // TODO: implement registrazione
    throw UnimplementedError();
  }
  
}