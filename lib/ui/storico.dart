import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/storico/storicoBloc.dart';
import 'package:thepadel/bloc/storico/storicoEvent.dart';
import 'package:thepadel/bloc/storico/storicoState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/partitaStorico.dart';
import 'package:thepadel/domainLayer/enetity/risultatoPartita.dart';

import 'bachecaPubbliche.dart';
import 'barraNavigazione.dart';
import 'dettaglioPartita.dart';
import 'prenota.dart';
import 'stileApp.dart';

class StoricoPage extends StatelessWidget {
  const StoricoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StoricoBloc>(
      create: (_) => sl<StoricoBloc>()..add(const StoricoRichiesto()),
      child: const _StoricoView(),
    );
  }
}

class _StoricoView extends StatelessWidget {
  const _StoricoView();

  void _ricarica(BuildContext context) {
    context.read<StoricoBloc>().add(const StoricoRichiesto());
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: Colori.sfondo,
      bottomNavigationBar: const BarraNavigazione(
        voceAttiva: VoceBarra.storico,
      ),
      body: SafeArea(
        child: ContenutoCentrato(
          child: BlocBuilder<StoricoBloc, StoricoState>(
            builder: (context, state) {
              List<Widget> elementi;
              if (state is StoricoCaricato) {
                elementi = _buildCaricato(context, r, state.partite);
              } else if (state is StoricoErrore) {
                elementi = [
                  Text('Storico partite', style: stileTitolo(r)),
                  const SizedBox(height: 12),
                  CardErrore(
                    titolo: 'Non siamo riusciti a caricare lo storico',
                    testo: state.messaggio,
                    onRiprova: () {
                      _ricarica(context);
                    },
                  ),
                ];
              } else {
                elementi = _buildScheletro();
              }

              return RefreshIndicator(
                color: Colori.primario,
                onRefresh: () async {
                  _ricarica(context);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  children: elementi,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ===== CARICAMENTO =====

  List<Widget> _buildScheletro() {
    final List<Widget> righe = [];
    for (int i = 0; i < 4; i++) {
      righe.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BarraGrigia(larghezza: 150, altezza: 18),
                  BarraGrigia(larghezza: 90, altezza: 22, raggio: 999),
                ],
              ),
              SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BarraGrigia(larghezza: 170, altezza: 16),
                  BarraGrigia(larghezza: 60, altezza: 16),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return [
      const BarraGrigia(larghezza: 200, altezza: 30),
      const SizedBox(height: 12),
      CardBianca(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(children: righe),
      ),
    ];
  }

  // ===== CONTENUTO =====

  List<Widget> _buildCaricato(
    BuildContext context,
    Responsive r,
    List<PartitaStorico> partite,
  ) {
    if (partite.isEmpty) {
      return _buildVuoto(context, r);
    }

    final List<Widget> elementi = [..._buildIntestazione(r, partite)];

    // basta una partita alla volta: finita questa compare la successiva
    PartitaStorico? senzaRisultato;
    for (final partita in partite) {
      if (senzaRisultato == null && _mancaRisultato(partita)) {
        senzaRisultato = partita;
      }
    }
    if (senzaRisultato != null) {
      elementi.add(const SizedBox(height: 12));
      elementi.add(_buildManca(context, r, senzaRisultato));
    }

    final List<Widget> righe = [];
    for (int i = 0; i < partite.length; i++) {
      if (i > 0) {
        righe.add(const Divider(height: 1, color: Colori.bordo));
      }
      righe.add(_buildRiga(context, r, partite[i]));
    }
    elementi.add(const SizedBox(height: 12));
    elementi.add(
      CardBianca(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: righe,
        ),
      ),
    );
    return elementi;
  }

  // Una partita rimasta "creata" non si e' mai giocata davvero (senza quattro
  // giocatori viene annullata): li' non c'e' nulla da registrare.
  bool _senzaRisultato(PartitaStorico partita) {
    if (partita.risultato != null) {
      return false;
    }
    return partita.stato == 'confermata' || partita.stato == 'giocata';
  }

  // Il risultato si puo' registrare solo dalla fine della partita alle 24 ore
  // successive: e' la stessa regola che applica il server.
  bool _mancaRisultato(PartitaStorico partita) {
    if (!_senzaRisultato(partita)) {
      return false;
    }
    final DateTime fine = fineDellaPartita(
      partita.dataPartita,
      partita.oraInizio,
      partita.oraFine,
    );
    if (DateTime.now().isBefore(fine)) {
      return false;
    }
    return !_termineScaduto(partita);
  }

  bool _termineScaduto(PartitaStorico partita) {
    return termineRisultatoScaduto(
      partita.dataPartita,
      partita.oraInizio,
      partita.oraFine,
    );
  }

  List<Widget> _buildIntestazione(Responsive r, List<PartitaStorico> partite) {
    bool conEsito = false;
    for (final partita in partite) {
      final String? esito = partita.risultato?.esito;
      if (esito == 'VINTA' || esito == 'PERSA') {
        conEsito = true;
      }
    }

    // finche' non c'e' nessun risultato si spiega a cosa serve la pagina
    if (!conEsito) {
      return [
        Text('Storico partite', style: stileTitolo(r)),
        const SizedBox(height: 4),
        Text(
          'Qui troverai risultati e punti di ogni partita.',
          style: stileSecondario(r),
        ),
      ];
    }

    return [Text('Storico partite', style: stileTitolo(r))];
  }

  Widget _buildManca(
    BuildContext context,
    Responsive r,
    PartitaStorico partita,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colori.arancioChiaro,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manca il risultato di ${nomeGiorno(partita.dataPartita)}',
            style: stileTesto(
              r,
              base: 16,
              peso: FontWeight.w700,
              colore: Colori.arancio,
            ),
          ),
          Text(
            '${giornoEMese(partita.dataPartita)}, '
            '${formattaOra(partita.oraInizio)} - ${formattaOra(partita.oraFine)} · '
            '${partita.nomeCampo}',
            style: stileTesto(r),
          ),
          const SizedBox(height: 10),
          // il form del risultato ha bisogno del dettaglio con i giocatori, che
          // lo storico non ha: lo si raggiunge dalla pagina della partita
          BottonePieno(
            testo: 'Registra risultato',
            onPressed: () {
              _apriDettaglio(context, partita.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRiga(
    BuildContext context,
    Responsive r,
    PartitaStorico partita,
  ) {
    final RisultatoPartita? risultato = partita.risultato;
    final String punteggio = risultato == null ? '' : _testoSet(risultato);

    return InkWell(
      onTap: () {
        _apriDettaglio(context, partita.id);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    conMaiuscola(dataEstesa(partita.dataPartita)),
                    style: stileTesto(r, base: 16, peso: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                _pillola(partita),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${formattaOra(partita.oraInizio)} - '
                    '${formattaOra(partita.oraFine)} · ${partita.nomeCampo}',
                    style: stileSecondario(r),
                  ),
                ),
                if (punteggio.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(punteggio, style: stileNumero(r, 15)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // il server da' i set come squadra1-squadra2: se l'utente e' nella
  // squadra 2 li giriamo, cosi' il primo numero sono sempre i suoi game
  String _testoSet(RisultatoPartita risultato) {
    String testo = '';
    for (final set in risultato.set) {
      String punteggio = '${set.squadra1}-${set.squadra2}';
      if (risultato.squadraUtente == 2) {
        punteggio = '${set.squadra2}-${set.squadra1}';
      }
      if (testo.isEmpty) {
        testo = punteggio;
      } else {
        testo = '$testo $punteggio';
      }
    }
    return testo;
  }

  // i punti possono anche essere negativi: il segno meno lo mette gia' il numero
  String _testoPunti(int? punti) {
    if (punti == null) {
      return '';
    }
    if (punti >= 0) {
      return ' · +$punti pt';
    }
    return ' · $punti pt';
  }

  Widget _pillola(PartitaStorico partita) {
    final RisultatoPartita? risultato = partita.risultato;

    if (risultato != null && risultato.esito == 'VINTA') {
      return Pillola(
        testo: 'Vinta${_testoPunti(risultato.puntiAssegnati)}',
        sfondo: Colori.verdeChiaro,
        colore: Colori.verde,
      );
    }
    if (risultato != null && risultato.esito == 'PERSA') {
      return Pillola(
        testo: 'Persa${_testoPunti(risultato.puntiAssegnati)}',
        sfondo: Colori.bordo,
        colore: Colori.testo,
      );
    }
    if (_mancaRisultato(partita)) {
      return const Pillola(
        testo: 'Senza risultato',
        sfondo: Colori.arancioChiaro,
        colore: Colori.arancio,
      );
    }
    if (_senzaRisultato(partita) && _termineScaduto(partita)) {
      return const Pillola(
        testo: 'Risultato non registrato',
        sfondo: Colori.bordo,
        colore: Colori.testoSecondario,
      );
    }
    if (partita.stato == 'giocata') {
      return const Pillola(
        testo: 'Giocata',
        sfondo: Colori.bordo,
        colore: Colori.testo,
      );
    }
    return PillolaStato(stato: partita.stato);
  }

  // ===== VUOTO =====

  List<Widget> _buildVuoto(BuildContext context, Responsive r) {
    return [
      Text('Storico partite', style: stileTitolo(r)),
      const SizedBox(height: 4),
      Text(
        'Qui troverai risultati e punti di ogni partita.',
        style: stileSecondario(r),
      ),
      const SizedBox(height: 12),
      CardBianca(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Non hai ancora partite nello storico',
              style: stileTesto(r, base: 16, peso: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Prenota un campo o unisciti a una partita aperta.',
              style: stileSecondario(r),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: BottonePieno(
                    testo: 'Prenota un campo',
                    paddingOrizzontale: 8,
                    onPressed: () {
                      cambiaPagina(context, const PrenotaPage());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BottonePieno(
                    testo: 'Trova una partita',
                    paddingOrizzontale: 8,
                    sfondo: Colori.azzurroChiaro,
                    coloreTesto: Colori.azzurro,
                    onPressed: () {
                      cambiaPagina(context, const BachecaPubblichePage());
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  Future<void> _apriDettaglio(BuildContext context, int idPartita) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => DettaglioPartitaPage(idPartita: idPartita),
      ),
    );

    if (context.mounted) {
      _ricarica(context);
    }
  }
}
