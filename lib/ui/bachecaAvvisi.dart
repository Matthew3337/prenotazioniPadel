import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/bachecaAvvisi/bachecaAvvisiBloc.dart';
import 'package:thepadel/bloc/bachecaAvvisi/bachecaAvvisiEvent.dart';
import 'package:thepadel/bloc/bachecaAvvisi/bachecaAvvisiState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/avvisoAdmin.dart';

import 'dettaglioAdmin.dart';
import 'stileApp.dart';

class BachecaAvvisiPage extends StatelessWidget {
  const BachecaAvvisiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BachecaAvvisiBloc>(
      create:
          (_) => sl<BachecaAvvisiBloc>()..add(const BachecaAvvisiRichiesta()),
      child: const _BachecaAvvisiView(),
    );
  }
}

class _BachecaAvvisiView extends StatelessWidget {
  const _BachecaAvvisiView();

  void _ricarica(BuildContext context) {
    context.read<BachecaAvvisiBloc>().add(const BachecaAvvisiRichiesta());
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: Colori.sfondo,
      body: SafeArea(
        child: ContenutoCentrato(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TestataIndietro(titolo: 'Bacheca avvisi'),
              Expanded(
                child: BlocBuilder<BachecaAvvisiBloc, BachecaAvvisiState>(
                  builder: (context, state) {
                    List<Widget> elementi;
                    if (state is BachecaAvvisiCaricata) {
                      elementi = _buildCaricata(context, r, state.avvisi);
                    } else if (state is BachecaAvvisiErrore) {
                      elementi = [
                        CardErrore(
                          titolo: 'Non siamo riusciti a caricare gli avvisi',
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
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        children: elementi,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== CARICAMENTO =====

  List<Widget> _buildScheletro() {
    final List<Widget> elementi = [];
    for (int i = 0; i < 3; i++) {
      elementi.add(const BarraGrigia(altezza: 96, raggio: 20));
      elementi.add(const SizedBox(height: 12));
    }
    return elementi;
  }

  // ===== CONTENUTO =====

  List<Widget> _buildCaricata(
    BuildContext context,
    Responsive r,
    List<AvvisoAdmin> avvisi,
  ) {
    if (avvisi.isEmpty) {
      return [
        CardBianca(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text('Nessun avviso aperto', style: stileTesto(r, base: 16)),
        ),
      ];
    }

    final List<Widget> elementi = [];
    for (final avviso in avvisi) {
      elementi.add(_buildAvviso(context, r, avviso));
      elementi.add(const SizedBox(height: 12));
    }
    return elementi;
  }

  Widget _buildAvviso(BuildContext context, Responsive r, AvvisoAdmin avviso) {
    return CardBianca(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () {
        _apriDettaglio(context, avviso.idPartita);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(avviso.nomeCampo, style: stileNumero(r, 18)),
          const SizedBox(height: 2),
          Text(
            '${conMaiuscola(dataEstesa(avviso.dataPartita))}, '
            '${formattaOra(avviso.oraInizio)} - ${formattaOra(avviso.oraFine)}',
            style: stileSecondario(r),
          ),
          const SizedBox(height: 8),
          Pillola(
            testo: testoPostiLiberi(avviso.postiLiberi),
            sfondo: Colori.arancioChiaro,
            colore: Colori.arancio,
          ),
        ],
      ),
    );
  }

  Future<void> _apriDettaglio(BuildContext context, int idPartita) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DettaglioAdminPage(idPartita: idPartita),
      ),
    );

    if (context.mounted) {
      _ricarica(context);
    }
  }
}
