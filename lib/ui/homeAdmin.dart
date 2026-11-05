import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/bloc/bachecaAvvisi/bachecaAvvisiBloc.dart';
import 'package:thepadel/bloc/bachecaAvvisi/bachecaAvvisiEvent.dart';
import 'package:thepadel/bloc/bachecaAvvisi/bachecaAvvisiState.dart';
import 'package:thepadel/bloc/livelloCampo/livelloCampoBloc.dart';
import 'package:thepadel/bloc/livelloCampo/livelloCampoEvent.dart';
import 'package:thepadel/bloc/livelloCampo/livelloCampoState.dart';
import 'package:thepadel/core/di/depInjection.dart';

import 'bachecaAvvisi.dart';
import 'bottoneEsci.dart';
import 'gestioneCampi.dart';
import 'gestioneLivelli.dart';
import 'nuovaPartitaAdmin.dart';
import 'partiteGiorno.dart';
import 'stileApp.dart';

class HomeAdminPage extends StatelessWidget {
  const HomeAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    // la bacheca qui serve solo a contare gli avvisi aperti
    return MultiBlocProvider(
      providers: [
        BlocProvider<BachecaAvvisiBloc>(
          create:
              (_) =>
                  sl<BachecaAvvisiBloc>()..add(const BachecaAvvisiRichiesta()),
        ),
        BlocProvider<LivelloCampoBloc>(
          create:
              (_) => sl<LivelloCampoBloc>()..add(const LivelloCampoRichiesto()),
        ),
      ],
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
                titolo: 'Nuova partita',
                sottotitolo: Text(
                  'Scegli campo, orario e giocatori',
                  style: stileSecondario(r),
                ),
                onTap: () {
                  _apri(context, const NuovaPartitaAdminPage());
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
              const SizedBox(height: 12),
              _buildVoce(
                r,
                titolo: 'Gestione campi',
                sottotitolo: Text(
                  'Aggiungi o modifica i campi e i loro orari',
                  style: stileSecondario(r),
                ),
                onTap: () {
                  _apri(context, const GestioneCampiPage());
                },
              ),
              const SizedBox(height: 12),
              _buildLivelloCampo(r),
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

  // ===== LIVELLO GIOCATORI CAMPO =====

  Widget _buildLivelloCampo(Responsive r) {
    return BlocConsumer<LivelloCampoBloc, LivelloCampoState>(
      listener: (context, state) {
        // se il primo caricamento fallisce lo dice gia' la card, con "Riprova"
        if (state is LivelloCampoErrore && state.livello != null) {
          mostraSnackBar(context, state.messaggio);
        }
      },
      builder: (context, state) {
        final bool nonCaricato =
            state is LivelloCampoErrore && state.livello == null;

        return CardBianca(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Livello giocatori campo', style: stileNumero(r, 18)),
                    const SizedBox(height: 2),
                    Text(
                      nonCaricato
                          ? 'Livello non disponibile'
                          : 'Vale per i prossimi calcoli dei punti',
                      style: stileSecondario(r),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // larghezza fissa: lo spinner non deve far saltare la riga
              SizedBox(
                width: 76,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _buildSelettoreLivello(context, r, state),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelettoreLivello(
    BuildContext context,
    Responsive r,
    LivelloCampoState state,
  ) {
    if (state is LivelloCampoCaricato) {
      return _buildTendinaLivello(context, r, state.livello);
    }
    if (state is LivelloCampoErrore) {
      final double? livello = state.livello;
      if (livello != null) {
        // il salvataggio e' fallito: il selettore torna all'ultimo valore buono
        return _buildTendinaLivello(context, r, livello);
      }
      return LinkTesto(
        testo: 'Riprova',
        onPressed: () {
          context.read<LivelloCampoBloc>().add(const LivelloCampoRichiesto());
        },
      );
    }
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: Colori.bluCampo,
      ),
    );
  }

  Widget _buildTendinaLivello(
    BuildContext context,
    Responsive r,
    double livello,
  ) {
    final List<DropdownMenuItem<double>> voci = [];
    // i livelli vanno da 0 a 5 con passo 0,5
    for (int i = 0; i <= 10; i++) {
      final double valore = i / 2;
      voci.add(
        DropdownMenuItem<double>(
          value: valore,
          child: Text('$valore', style: stileTesto(r)),
        ),
      );
    }

    // un livello fuori dal passo farebbe fallire il DropdownButton, che vuole
    // sempre un valore presente tra le voci: lo mostriamo solo come testo
    final bool valoreValido =
        livello >= 0 && livello <= 5 && (livello * 2) % 1 == 0;

    return Semantics(
      label: 'Livello giocatori campo',
      child: DropdownButton<double>(
        value: valoreValido ? livello : null,
        hint: Text('$livello', style: stileTesto(r)),
        underline: const SizedBox.shrink(),
        items: voci,
        onChanged: (nuovoLivello) {
          if (nuovoLivello == null || nuovoLivello == livello) {
            return;
          }
          context.read<LivelloCampoBloc>().add(
            CambiaLivelloCampoRichiesto(livello: nuovoLivello),
          );
        },
      ),
    );
  }
}
