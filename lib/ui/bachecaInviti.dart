import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/bachecaInviti/bachecaInvitiBloc.dart';
import 'package:thepadel/bloc/bachecaInviti/bachecaInvitiEvent.dart';
import 'package:thepadel/bloc/bachecaInviti/bachecaInvitiState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/invitoBacheca.dart';
import 'package:thepadel/domainLayer/enetity/partitaInvito.dart';

import 'bachecaPubbliche.dart';
import 'barraNavigazione.dart';
import 'campoPadel.dart';
import 'dettaglioPartita.dart';
import 'stileApp.dart';

class BachecaInvitiPage extends StatelessWidget {
  const BachecaInvitiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BachecaInvitiBloc>(
      create: (_) => sl<BachecaInvitiBloc>()..add(const BachecaInvitiRichiesta()),
      child: const _BachecaInvitiView(),
    );
  }
}

class _BachecaInvitiView extends StatelessWidget {
  const _BachecaInvitiView();

  void _ricarica(BuildContext context) {
    context.read<BachecaInvitiBloc>().add(const BachecaInvitiRichiesta());
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: Colori.sfondo,
      bottomNavigationBar: const BarraNavigazione(
        voceAttiva: VoceBarra.partite,
      ),
      body: SafeArea(
        child: ContenutoCentrato(
          child: BlocConsumer<BachecaInvitiBloc, BachecaInvitiState>(
            listener: (context, state) {
              if (state is ConfermaInvitoRiuscita) {
                // se con questa conferma ci sono tutti lo diciamo, come nel
                // dettaglio partita
                if (state.dettaglio.stato == 'confermata') {
                  mostraSnackBar(context, 'Partita confermata: ci sono tutti!');
                } else {
                  mostraSnackBar(context, 'Partecipazione confermata');
                }
              }
              if (state is ConfermaInvitoErrore) {
                mostraSnackBar(context, state.messaggio);
              }
            },
            builder: (context, state) {
              // gli stati della conferma sono anche dei Caricata: la lista
              // resta a schermo per tutta l'operazione
              List<InvitoBacheca>? voci;
              int? idInConferma;
              if (state is BachecaInvitiCaricata) {
                voci = state.voci;
              }
              if (state is ConfermaInvitoInCorso) {
                idInConferma = state.idPartita;
              }

              final bool inErrore = state is BachecaInvitiErrore;

              final List<Widget> elementi = [
                Text('Partite', style: stileTitolo(r)),
                const SizedBox(height: 12),
                _buildSchede(voci, inErrore),
              ];

              if (state is BachecaInvitiErrore) {
                elementi.add(const SizedBox(height: 12));
                elementi.add(
                  CardErrore(
                    titolo: 'Non siamo riusciti a caricare gli inviti',
                    testo: state.messaggio,
                    onRiprova: () {
                      _ricarica(context);
                    },
                  ),
                );
              } else if (voci == null) {
                for (int i = 0; i < 2; i++) {
                  elementi.add(const SizedBox(height: 12));
                  elementi.add(_scheletroCard());
                }
              } else if (voci.isEmpty) {
                elementi.add(const SizedBox(height: 12));
                elementi.add(_buildVuota(context, r));
              } else {
                for (final voce in voci) {
                  elementi.add(const SizedBox(height: 12));
                  elementi.add(_buildInvito(context, r, voce, idInConferma));
                }
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

  Widget _buildSchede(List<InvitoBacheca>? voci, bool inErrore) {
    String? conteggio;
    if (voci != null) {
      conteggio = voci.length == 1 ? '1 ricevuto' : '${voci.length} ricevuti';
    }
    return SchedePartite(
      inviti: true,
      conteggio: conteggio,
      inCaricamento: voci == null && !inErrore,
    );
  }

  Widget _scheletroCard() {
    return const CardBianca(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BarraGrigia(larghezza: 44, altezza: 44, raggio: 22),
              SizedBox(width: 12),
              Expanded(child: BarraGrigia(larghezza: 180, altezza: 18)),
            ],
          ),
          SizedBox(height: 12),
          BarraGrigia(larghezza: 150, altezza: 22),
          SizedBox(height: 6),
          BarraGrigia(larghezza: 240, altezza: 16),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BarraGrigia(larghezza: 100, altezza: 18),
              BarraGrigia(larghezza: 100, altezza: 44, raggio: 999),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVuota(BuildContext context, Responsive r) {
    return CardBianca(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Non hai inviti al momento',
            style: stileTesto(r, base: 16, peso: FontWeight.w600),
          ),
          LinkTesto(
            testo: 'Guarda le partite pubbliche',
            onPressed: () {
              cambiaPagina(context, const BachecaPubblichePage());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInvito(
    BuildContext context,
    Responsive r,
    InvitoBacheca voce,
    int? idInConferma,
  ) {
    final PartitaInvito partita = voce.partita;
    final String tipo = partita.tipo == 'PUBBLICA' ? 'Pubblica' : 'Privata';

    // il colore cambia da invito a invito, ma resta lo stesso per ogni partita
    const List<Color> sfondi = [
      Colori.verdeChiaro,
      Colori.rossoChiaro,
      Colori.arancioChiaro,
    ];
    const List<Color> colori = [Colori.verde, Colori.rosso, Colori.arancio];
    final int tinta = partita.id % sfondi.length;

    Widget azione = const SizedBox.shrink();
    if (voce.puoConfermare) {
      azione = BottonePieno(
        testo: 'Conferma',
        paddingOrizzontale: 22,
        inCaricamento: idInConferma == partita.id,
        // il bloc segue una conferma per volta
        onPressed:
            idInConferma != null
                ? null
                : () {
                  context.read<BachecaInvitiBloc>().add(
                    ConfermaInvitoRichiesta(idPartita: partita.id),
                  );
                },
      );
    } else if (voce.giaConfermato) {
      azione = const Pillola(
        testo: 'Confermato',
        sfondo: Colori.verdeChiaro,
        colore: Colori.verde,
      );
    }

    return CardBianca(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CerchioIniziali(
                testo: inizialiDi(partita.nomeCreatore, partita.cognomeCreatore),
                sfondo: sfondi[tinta],
                colore: colori[tinta],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            '${partita.nomeCreatore} ${partita.cognomeCreatore}',
                        style: stileTesto(r, base: 16, peso: FontWeight.w700),
                      ),
                      TextSpan(
                        text: ' ti ha invitato',
                        style: stileSecondario(r),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${conMaiuscola(giornoRelativo(partita.dataPartita))}, '
            '${formattaOra(partita.oraInizio)}',
            style: stileNumero(r, 20),
          ),
          const SizedBox(height: 2),
          Text(
            '${partita.nomeCampo} · ${giornoEMese(partita.dataPartita)}, '
            '${formattaOra(partita.oraInizio)} - ${formattaOra(partita.oraFine)} · $tipo',
            style: stileSecondario(r),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LinkTesto(
                testo: 'Vedi la partita',
                onPressed: () {
                  _apriDettaglio(context, partita.id);
                },
              ),
              azione,
            ],
          ),
        ],
      ),
    );
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
