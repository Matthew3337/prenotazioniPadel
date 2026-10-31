abstract class BachecaPubblicheEvent {
  const BachecaPubblicheEvent();
}

class BachecaPubblicheRichiesta extends BachecaPubblicheEvent {
  const BachecaPubblicheRichiesta();
}

class EntraInPartitaRichiesto extends BachecaPubblicheEvent {
  final int idPartita;
  const EntraInPartitaRichiesto({required this.idPartita});
}
