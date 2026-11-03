import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/bachecaPubbliche/bachecaPubblicheBloc.dart';
import 'package:thepadel/bloc/bachecaPubbliche/bachecaPubblicheEvent.dart';
import 'package:thepadel/bloc/bachecaPubbliche/bachecaPubblicheState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/partitaPubblica.dart';

import 'barraNavigazione.dart';
import 'campoPadel.dart';
import 'dettaglioPartita.dart';
import 'prenota.dart';
import 'stileApp.dart';

class BachecaPubblichePage extends StatelessWidget {
  const BachecaPubblichePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BachecaPubblicheBloc>(
      create:
          (_) =>
              sl<BachecaPubblicheBloc>()
                ..add(const BachecaPubblicheRichiesta()),
      child: const _BachecaPubblicheView(),
    );
  }
}

class _BachecaPubblicheView extends StatelessWidget {
  const _BachecaPubblicheView();

  void _ricarica(BuildContext context) {
    context.read<BachecaPubblicheBloc>().add(const BachecaPubblicheRichiesta());
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
          child: BlocConsumer<BachecaPubblicheBloc, BachecaPubblicheState>(
            listener: (context, state) {
              if (state is IngressoRiuscito) {
                _apriDettaglio(context, state.dettaglio.id);
              }
              // dopo l'errore il BLoC ricarica la bacheca da solo,
              // qui basta avvisare l'utente
              if (state is IngressoErrore) {
                mostraSnackBar(context, state.messaggio);
              }
            },
            builder: (context, state) {
              List<PartitaPubblica>? partite;
              int? idInIngresso;
              if (state is BachecaPubblicheCaricata) {
                partite = state.partite;
              }
              // durante l'ingresso la lista resta a schermo e solo il bottone
              // della partita scelta mostra lo spinner
              if (state is IngressoInCorso) {
                partite = state.partite;
                idInIngresso = state.idPartita;
              }
              if (state is IngressoRiuscito) {
                partite = state.partite;
              }
              if (state is IngressoErrore) {
                partite = state.partite;
              }

              final bool inErrore = state is BachecaPubblicheErrore;

              final List<Widget> elementi = [
                Text('Partite', style: stileTitolo(r)),
                const SizedBox(height: 12),
                _buildSchede(partite, inErrore),
                const SizedBox(height: 12),
              ];

              if (state is BachecaPubblicheErrore) {
                elementi.add(
                  CardErrore(
                    titolo: 'Non siamo riusciti a caricare le partite',
                    testo: state.messaggio,
                    onRiprova: () {
                      _ricarica(context);
                    },
                  ),
                );
              } else if (partite == null) {
                elementi.add(const BarraGrigia(larghezza: 300, altezza: 18));
                for (int i = 0; i < 3; i++) {
                  elementi.add(const SizedBox(height: 12));
                  elementi.add(_scheletroCard());
                }
              } else if (partite.isEmpty) {
                elementi.add(_buildVuota(context, r));
              } else {
                elementi.add(
                  Text(
                    'Partite aperte a giocatori di livello simile al tuo.',
                    style: stileSecondario(r),
                  ),
                );
                for (final partita in partite) {
                  elementi.add(const SizedBox(height: 12));
                  elementi.add(
                    _buildPartita(context, r, partita, idInIngresso),
                  );
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

  Widget _buildSchede(List<PartitaPubblica>? partite, bool inErrore) {
    String? conteggio;
    if (partite != null) {
      conteggio =
          partite.length == 1 ? '1 aperta' : '${partite.length} aperte';
    }
    return SchedePartite(
      inviti: false,
      conteggio: conteggio,
      inCaricamento: partite == null && !inErrore,
    );
  }

  Widget _scheletroCard() {
    return const CardBianca(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BarraGrigia(larghezza: 76, altezza: 46, raggio: 8),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BarraGrigia(larghezza: 150, altezza: 22),
                    SizedBox(height: 6),
                    BarraGrigia(larghezza: 190, altezza: 16),
                    SizedBox(height: 6),
                    BarraGrigia(larghezza: 160, altezza: 16),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BarraGrigia(larghezza: 100, altezza: 24, raggio: 999),
              BarraGrigia(larghezza: 84, altezza: 44, raggio: 999),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVuota(BuildContext context, Responsive r) {
    return CardBianca(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CampoPadel(altezza: 130, posti: []),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nessuna partita pubblica disponibile al momento',
                  style: stileTesto(r, base: 16, peso: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Puoi aprirne una tu: prenota un campo e scegli "Partita pubblica".',
                  style: stileSecondario(r),
                ),
                const SizedBox(height: 12),
                BottonePieno(
                  testo: 'Prenota un campo',
                  onPressed: () {
                    cambiaPagina(context, const PrenotaPage());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartita(
    BuildContext context,
    Responsive r,
    PartitaPubblica partita,
    int? idInIngresso,
  ) {
    final bool unPosto = partita.postiLiberi == 1;
    final String giorno = giornoRelativo(partita.dataPartita);
    final String orario =
        '${formattaOra(partita.oraInizio)} - ${formattaOra(partita.oraFine)}';

    // oggi basta l'orario, per gli altri giorni serve anche la data
    String dove = '${partita.nomeCampo} · $orario';
    if (giorno != 'oggi') {
      dove =
          '${partita.nomeCampo} · ${giornoEMese(partita.dataPartita)}, $orario';
    }

    return CardBianca(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MiniCampo(postiLiberi: partita.postiLiberi),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${conMaiuscola(giorno)}, ${formattaOra(partita.oraInizio)}',
                      style: stileNumero(r, 20),
                    ),
                    Text(dove, style: stileSecondario(r)),
                    Text(
                      '${partita.nomeCreatore} ${partita.cognomeCreatore} · '
                      'Livello ${partita.livelloCreatore}',
                      style: stileSecondario(r),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Pillola(
                    testo:
                        unPosto
                            ? '1 posto libero'
                            : '${partita.postiLiberi} posti liberi',
                    sfondo:
                        unPosto ? Colori.arancioChiaro : Colori.azzurroChiaro,
                    colore: unPosto ? Colori.arancio : Colori.azzurro,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BottonePieno(
                testo: 'Entra',
                paddingOrizzontale: 22,
                inCaricamento: idInIngresso == partita.id,
                // un ingresso per volta: lo stato ne segue uno solo
                onPressed:
                    idInIngresso != null
                        ? null
                        : () {
                          context.read<BachecaPubblicheBloc>().add(
                            EntraInPartitaRichiesto(idPartita: partita.id),
                          );
                        },
              ),
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
