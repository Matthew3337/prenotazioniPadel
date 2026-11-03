import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/bloc/bachecaAvvisi/bachecaAvvisiBloc.dart';
import 'package:thepadel/bloc/bachecaAvvisi/bachecaAvvisiEvent.dart';
import 'package:thepadel/bloc/bachecaAvvisi/bachecaAvvisiState.dart';
import 'package:thepadel/core/di/depInjection.dart';

import 'bachecaAvvisi.dart';
import 'bottoneEsci.dart';
import 'gestioneLivelli.dart';
import 'partiteGiorno.dart';
import 'stileApp.dart';

class HomeAdminPage extends StatelessWidget {
  const HomeAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    // la bacheca qui serve solo a contare gli avvisi aperti
    return BlocProvider<BachecaAvvisiBloc>(
      create:
          (_) => sl<BachecaAvvisiBloc>()..add(const BachecaAvvisiRichiesta()),
      child: const _HomeAdminView(),
    );
  }
}

class _HomeAdminView extends StatelessWidget {
  const _HomeAdminView();

  // chi ha fatto il login con una versione vecchia dell'app non ha il nome salvato
  String _saluto() {
    final String? nome = sl<SharedPreferences>().getString('nome');
    if (nome == null || nome.isEmpty) {
      return 'Ciao';
    }
    return 'Ciao, $nome';
  }

  // dalle altre pagine si puo' annullare una partita o cambiarne i posti, e
  // il numero di avvisi cambia: al ritorno lo chiediamo sempre di nuovo
  Future<void> _apri(BuildContext context, Widget pagina) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => pagina),
    );

    if (context.mounted) {
      context.read<BachecaAvvisiBloc>().add(const BachecaAvvisiRichiesta());
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: Colori.sfondo,
      body: SafeArea(
        child: ContenutoCentrato(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            children: [
              Text(_saluto(), style: stileTitolo(r)),
              const SizedBox(height: 4),
              Text('Area amministratore', style: stileSecondario(r)),
              const SizedBox(height: 16),
              _buildVoce(
                r,
                titolo: 'Partite del giorno',
                sottotitolo: Text(
                  'Tutte le partite di un giorno, campo per campo',
                  style: stileSecondario(r),
                ),
                onTap: () {
                  _apri(context, const PartiteGiornoPage());
                },
              ),
              const SizedBox(height: 12),
              _buildVoce(
                r,
                titolo: 'Bacheca avvisi',
                sottotitolo: _buildNumeroAvvisi(r),
                onTap: () {
                  _apri(context, const BachecaAvvisiPage());
                },
              ),
              const SizedBox(height: 12),
              _buildVoce(
                r,
                titolo: 'Gestione livelli',
                sottotitolo: Text(
                  'Cerca un utente e cambia il suo livello',
                  style: stileSecondario(r),
                ),
                onTap: () {
                  _apri(context, const GestioneLivelliPage());
                },
              ),
              const SizedBox(height: 8),
              const BottoneEsci(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoce(
    Responsive r, {
    required String titolo,
    required Widget sottotitolo,
    required VoidCallback onTap,
  }) {
    return CardBianca(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titolo, style: stileNumero(r, 18)),
                const SizedBox(height: 2),
                sottotitolo,
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colori.grigio),
        ],
      ),
    );
  }

  Widget _buildNumeroAvvisi(Responsive r) {
    return BlocBuilder<BachecaAvvisiBloc, BachecaAvvisiState>(
      builder: (context, state) {
        if (state is BachecaAvvisiCaricata) {
          final int numero = state.avvisi.length;
          if (numero == 0) {
            return Text('Nessun avviso aperto', style: stileSecondario(r));
          }
          return Text(
            numero == 1 ? '1 avviso aperto' : '$numero avvisi aperti',
            style: stileTesto(r, peso: FontWeight.w600, colore: Colori.arancio),
          );
        }
        // la voce resta comunque apribile: l'errore vero lo mostra la bacheca
        if (state is BachecaAvvisiErrore) {
          return Text(
            'Numero di avvisi non disponibile',
            style: stileSecondario(r),
          );
        }
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 3),
          child: BarraGrigia(larghezza: 130, altezza: 16),
        );
      },
    );
  }
}
