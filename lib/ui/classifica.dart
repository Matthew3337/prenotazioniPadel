import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/classifica/classificaBloc.dart';
import 'package:thepadel/bloc/classifica/classificaEvent.dart';
import 'package:thepadel/bloc/classifica/classificaState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/voceClassifica.dart';

import 'barraNavigazione.dart';
import 'stileApp.dart';

class ClassificaPage extends StatelessWidget {
  const ClassificaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ClassificaBloc>(
      create: (_) => sl<ClassificaBloc>()..add(const ClassificaRichiesta()),
      child: const _ClassificaView(),
    );
  }
}

class _ClassificaView extends StatelessWidget {
  const _ClassificaView();

  void _ricarica(BuildContext context) {
    context.read<ClassificaBloc>().add(const ClassificaRichiesta());
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: Colori.sfondo,
      bottomNavigationBar: const BarraNavigazione(
        voceAttiva: VoceBarra.classifica,
      ),
      body: SafeArea(
        child: ContenutoCentrato(
          child: BlocBuilder<ClassificaBloc, ClassificaState>(
            builder: (context, state) {
              List<Widget> elementi;
              if (state is ClassificaCaricata) {
                elementi = _buildCaricata(r, state.voci);
              } else if (state is ClassificaErrore) {
                elementi = [
                  Text('Classifica', style: stileTitolo(r)),
                  const SizedBox(height: 12),
                  CardErrore(
                    titolo: 'Non siamo riusciti a caricare la classifica',
                    testo:
                        'Controlla la connessione. Se il problema resta, riprova più tardi.',
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
    for (int i = 0; i < 8; i++) {
      righe.add(
        const SizedBox(
          height: 58,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                BarraGrigia(larghezza: 20, altezza: 20),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BarraGrigia(larghezza: 140, altezza: 16),
                      SizedBox(height: 5),
                      BarraGrigia(altezza: 4, raggio: 2),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                BarraGrigia(larghezza: 54, altezza: 18),
              ],
            ),
          ),
        ),
      );
    }

    return [
      const BarraGrigia(larghezza: 160, altezza: 30),
      const SizedBox(height: 12),
      CardBianca(
        padding: const EdgeInsets.all(6),
        child: Column(children: righe),
      ),
    ];
  }

  // ===== CONTENUTO =====

  List<Widget> _buildCaricata(Responsive r, List<VoceClassifica> voci) {
    final List<Widget> elementi = [];
    elementi.add(Text('Classifica', style: stileTitolo(r)));
    elementi.add(const SizedBox(height: 12));

    if (voci.isEmpty) {
      elementi.add(
        CardBianca(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Nessun giocatore in classifica',
            style: stileSecondario(r),
          ),
        ),
      );
      return elementi;
    }

    // il server manda la lista gia' ordinata: il primo ha il punteggio piu' alto
    final int massimo = voci.first.punteggio;
    final List<Widget> righe = [];
    for (final voce in voci) {
      righe.add(_buildRiga(r, voce, massimo));
    }

    elementi.add(
      CardBianca(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: righe,
        ),
      ),
    );
    return elementi;
  }

  Widget _buildRiga(Responsive r, VoceClassifica voce, int massimo) {
    final bool sono = voce.utenteCorrente;

    double proporzione = 0;
    if (massimo > 0) {
      proporzione = (voce.punteggio / massimo).clamp(0.0, 1.0);
    }

    String nome = '${voce.nome} ${voce.cognome}';
    if (sono) {
      nome = '$nome (tu)';
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: sono ? Colori.azzurroChiaro : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: r.font(28),
            child: Text('${voce.posizione}', style: stileNumero(r, 17)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  nome,
                  style: stileTesto(
                    r,
                    peso: sono ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  height: 4,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colori.bordo,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: proporzione,
                    child: Container(
                      decoration: BoxDecoration(
                        color: sono ? Colori.bluCampo : Colori.grigio,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${voce.punteggio} ',
                  style: stileTesto(r, peso: FontWeight.w700),
                ),
                TextSpan(text: 'pt', style: stileSecondario(r, base: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
