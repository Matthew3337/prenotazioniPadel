import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/bloc/bachecaAvvisi/bachecaAvvisiBloc.dart';
import 'package:thepadel/bloc/bachecaAvvisi/bachecaAvvisiEvent.dart';
import 'package:thepadel/bloc/bachecaAvvisi/bachecaAvvisiState.dart';
import 'package:thepadel/bloc/livelloCampo/livelloCampoBloc.dart';
import 'package:thepadel/bloc/livelloCampo/livelloCampoEvent.dart';
import 'package:thepadel/bloc/livelloCampo/livelloCampoState.dart';
import 'package:thepadel/bloc/prenota/prenotaBloc.dart';
import 'package:thepadel/bloc/prenota/prenotaEvent.dart';
import 'package:thepadel/bloc/prenota/prenotaState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/campo.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';

import 'bachecaAvvisi.dart';
import 'bottoneEsci.dart';
import 'gestioneCampi.dart';
import 'gestioneLivelli.dart';
import 'nuovaPartitaAdmin.dart';
import 'partiteGiorno.dart';
import 'stileApp.dart';
import 'tabelloneSlot.dart';

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
        // giorni, campi e slot sono gli stessi della pagina di prenotazione:
        // l'admin non gioca, quindi le sue partite arrivano sempre vuote
        BlocProvider<PrenotaBloc>(
          create: (_) => sl<PrenotaBloc>()..add(const PrenotaRichiesta()),
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

  // dalle altre pagine si puo' creare o annullare una partita o cambiarne i
  // posti: al ritorno chiediamo di nuovo sia gli avvisi sia gli slot liberi
  Future<void> _apri(BuildContext context, Widget pagina) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => pagina),
    );

    if (context.mounted) {
      context.read<BachecaAvvisiBloc>().add(const BachecaAvvisiRichiesta());
      context.read<PrenotaBloc>().add(const PrenotaRichiesta());
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
              _buildSlotLiberi(context, r),
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

  // ===== SLOT LIBERI =====

  Widget _buildSlotLiberi(BuildContext context, Responsive r) {
    return BlocBuilder<PrenotaBloc, PrenotaState>(
      builder: (context, state) {
        return CardBianca(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Slot liberi', style: stileNumero(r, 18)),
              const SizedBox(height: 2),
              Text(
                'Tocca un orario per creare una partita',
                style: stileSecondario(r),
              ),
              const SizedBox(height: 12),
              BarraGiorni(
                state: state,
                onGiornoScelto: (giorno) {
                  context.read<PrenotaBloc>().add(
                    PrenotaGiornoCambiato(giorno: giorno),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildContenutoSlot(context, r, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContenutoSlot(
    BuildContext context,
    Responsive r,
    PrenotaState state,
  ) {
    // la sezione e' gia' dentro una card: l'errore non usa CardErrore per non
    // mettere una card dentro l'altra
    if (state is PrenotaErrore) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Non siamo riusciti a caricare gli slot di ${nomeGiorno(state.giorno)}',
            style: stileTesto(r, peso: FontWeight.w600, colore: Colori.rosso),
          ),
          LinkTesto(
            testo: 'Riprova',
            onPressed: () {
              context.read<PrenotaBloc>().add(const PrenotaRichiesta());
            },
          ),
        ],
      );
    }

    if (state is PrenotaCaricato) {
      if (state.campi.isEmpty) {
        return Text(
          'Non ci sono campi. Puoi aggiungerli da Gestione campi.',
          style: stileSecondario(r),
        );
      }

      final DateTime adesso = DateTime.now();
      final List<Widget> righe = [];
      for (final campo in state.campi) {
        if (righe.isNotEmpty) {
          righe.add(const SizedBox(height: 8));
        }
        righe.add(
          _rigaCampo(
            context,
            r,
            state,
            campo,
            _slotLiberi(state, campo, adesso),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: righe,
      );
    }

    return Column(
      children: [
        _rigaScheletroSlot(),
        const SizedBox(height: 8),
        _rigaScheletroSlot(),
      ],
    );
  }

  // il server segna come disponibili anche gli slot gia' iniziati: quelli
  // vanno tolti a parte
  List<SlotOrario> _slotLiberi(
    PrenotaCaricato state,
    Campo campo,
    DateTime adesso,
  ) {
    final List<SlotOrario> liberi = [];
    final List<SlotOrario> slots = state.slotPerCampo[campo.id] ?? [];
    for (final slot in slots) {
      if (slot.disponibile && !state.slotPassato(slot, adesso)) {
        liberi.add(slot);
      }
    }
    return liberi;
  }

  Widget _rigaScheletroSlot() {
    const Widget spazio = SizedBox(width: 6);
    const Widget casella = Expanded(
      child: BarraGrigia(altezza: 44, raggio: 10),
    );
    return const Row(
      children: [
        SizedBox(width: 56, child: BarraGrigia(altezza: 16)),
        SizedBox(width: 8),
        casella,
        spazio,
        casella,
        spazio,
        casella,
      ],
    );
  }

  // come nella home dell'utente: il nome del campo resta fermo a sinistra e
  // gli orari scorrono di lato se non entrano nella card. Un campo pieno resta
  // in elenco con una scritta, cosi' l'admin vede che non e' stato dimenticato
  Widget _rigaCampo(
    BuildContext context,
    Responsive r,
    PrenotaCaricato state,
    Campo campo,
    List<SlotOrario> liberi,
  ) {
    Widget orari;
    if (liberi.isEmpty) {
      orari = Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.centerLeft,
        child: Text('Nessuno slot libero', style: stileSecondario(r)),
      );
    } else {
      final List<Widget> caselle = [];
      for (int i = 0; i < liberi.length; i++) {
        if (i > 0) {
          caselle.add(const SizedBox(width: 6));
        }
        caselle.add(
          SizedBox(
            width: r.font(64),
            child: _casellaSlot(context, r, state, liberi[i]),
          ),
        );
      }
      orari = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: caselle),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: r.font(64),
          child: Text(
            campo.nome,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: stileTesto(r, peso: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: orari),
      ],
    );
  }

  Widget _casellaSlot(
    BuildContext context,
    Responsive r,
    PrenotaCaricato state,
    SlotOrario slot,
  ) {
    return Semantics(
      label: '${slot.nomeCampo}, ${oraBreve(slot.oraInizio)}, libero',
      button: true,
      child: Material(
        color: Colori.verdeChiaro,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () {
            _apri(
              context,
              NuovaPartitaAdminPage(
                giornoIniziale: state.giorno,
                slotIniziale: slot,
              ),
            );
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.center,
            child: Text(
              oraBreve(slot.oraInizio),
              maxLines: 1,
              style: stileTesto(r, peso: FontWeight.w700, colore: Colori.verde),
            ),
          ),
        ),
      ),
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
