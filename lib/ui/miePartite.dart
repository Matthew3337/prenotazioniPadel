import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/miePartite/miePartiteBloc.dart';
import 'package:thepadel/bloc/miePartite/miePartiteEvent.dart';
import 'package:thepadel/bloc/miePartite/miePartiteState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/partitaStorico.dart';

import 'bachecaPubbliche.dart';
import 'barraNavigazione.dart';
import 'dettaglioPartita.dart';
import 'prenota.dart';
import 'stileApp.dart';

class MiePartitePage extends StatelessWidget {
  const MiePartitePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MiePartiteBloc>(
      create: (_) => sl<MiePartiteBloc>()..add(const MiePartiteRichieste()),
      child: const _MiePartiteView(),
    );
  }
}

class _MiePartiteView extends StatelessWidget {
  const _MiePartiteView();

  void _ricarica(BuildContext context) {
    context.read<MiePartiteBloc>().add(const MiePartiteRichieste());
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: Colori.sfondo,
      bottomNavigationBar: const BarraNavigazione(
        voceAttiva: VoceBarra.miePartite,
      ),
      body: SafeArea(
        child: ContenutoCentrato(
          child: BlocBuilder<MiePartiteBloc, MiePartiteState>(
            builder: (context, state) {
              List<Widget> elementi;
              if (state is MiePartiteCaricate) {
                elementi = _buildCaricate(context, r, state.partite);
              } else if (state is MiePartiteErrore) {
                elementi = [
                  Text('Le mie partite', style: stileTitolo(r)),
                  const SizedBox(height: 12),
                  CardErrore(
                    titolo: 'Non siamo riusciti a caricare le tue partite',
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
                children: [BarraGrigia(larghezza: 170, altezza: 16)],
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

  List<Widget> _buildCaricate(
    BuildContext context,
    Responsive r,
    List<PartitaStorico> partite,
  ) {
    if (partite.isEmpty) {
      return _buildVuoto(context, r);
    }

    final List<Widget> righe = [];
    for (int i = 0; i < partite.length; i++) {
      if (i > 0) {
        righe.add(const Divider(height: 1, color: Colori.bordo));
      }
      righe.add(_buildRiga(context, r, partite[i]));
    }

    return [
      Text('Le mie partite', style: stileTitolo(r)),
      const SizedBox(height: 12),
      CardBianca(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: righe,
        ),
      ),
    ];
  }

  Widget _buildRiga(
    BuildContext context,
    Responsive r,
    PartitaStorico partita,
  ) {
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
                PillolaStato(stato: partita.stato),
              ],
            ),
            Text(
              '${formattaOra(partita.oraInizio)} - '
              '${formattaOra(partita.oraFine)} · ${partita.nomeCampo}',
              style: stileSecondario(r),
            ),
          ],
        ),
      ),
    );
  }

  // ===== VUOTO =====

  List<Widget> _buildVuoto(BuildContext context, Responsive r) {
    return [
      Text('Le mie partite', style: stileTitolo(r)),
      const SizedBox(height: 12),
      CardBianca(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Non hai partite in programma',
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

    // al ritorno la partita puo' essere cambiata o non esserci piu'
    if (context.mounted) {
      _ricarica(context);
    }
  }
}
