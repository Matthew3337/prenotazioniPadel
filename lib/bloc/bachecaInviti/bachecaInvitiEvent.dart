abstract class BachecaInvitiEvent {
  const BachecaInvitiEvent();
}

class BachecaInvitiRichiesta extends BachecaInvitiEvent {
  const BachecaInvitiRichiesta();
}

class ConfermaInvitoRichiesta extends BachecaInvitiEvent {
  final int idPartita;
  const ConfermaInvitoRichiesta({required this.idPartita});
}
