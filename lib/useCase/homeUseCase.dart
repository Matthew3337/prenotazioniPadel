import 'package:thepadel/domainLayer/enetity/prenotazione.dart';
import 'package:thepadel/repositoryImpl/prenotazioneRepoImpl.dart';

class ProssimaPartitaUseCase {

  final PrenotazioneRepoImpl repo;

  ProssimaPartitaUseCase({required this.repo});

   Future<Prenotazione?> call()
   {
      return repo.getProssimaPartita();
   }
}