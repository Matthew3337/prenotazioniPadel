import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/gestioneLivelli/gestioneLivelliBloc.dart';
import 'package:thepadel/bloc/gestioneLivelli/gestioneLivelliEvent.dart';
import 'package:thepadel/bloc/gestioneLivelli/gestioneLivelliState.dart';
import 'package:thepadel/bloc/nuovaPartitaAdmin/nuovaPartitaAdminBloc.dart';
import 'package:thepadel/bloc/nuovaPartitaAdmin/nuovaPartitaAdminEvent.dart';
import 'package:thepadel/bloc/nuovaPartitaAdmin/nuovaPartitaAdminState.dart';
import 'package:thepadel/bloc/prenota/prenotaBloc.dart';
import 'package:thepadel/bloc/prenota/prenotaEvent.dart';
import 'package:thepadel/bloc/prenota/prenotaState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';
import 'package:thepadel/domainLayer/enetity/utenteAdmin.dart';

import 'dettaglioAdmin.dart';
import 'stileApp.dart';
import 'tabelloneSlot.dart';

class NuovaPartitaAdminPage extends StatelessWidget {
  // dagli slot liberi della home si arriva qui con giorno e slot gia' scelti;
  // lo slot contiene anche il campo
  final DateTime? giornoIniziale;
  final SlotOrario? slotIniziale;

  const NuovaPartitaAdminPage({
    super.key,
    this.giornoIniziale,
    this.slotIniziale,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NuovaPartitaAdminBloc>(
          create: (_) => sl<NuovaPartitaAdminBloc>(),
        ),
        // il tabellone degli slot e' lo stesso della pagina di prenotazione
        BlocProvider<PrenotaBloc>(
          create: (_) {
            final bloc = sl<PrenotaBloc>();
            final DateTime? giorno = giornoIniziale;
            if (giorno != null) {
              bloc.add(PrenotaGiornoCambiato(giorno: giorno));
            } else {
              bloc.add(const PrenotaRichiesta());
            }
            return bloc;
          },
        ),
        // questo serve solo per la ricerca degli utenti
        BlocProvider<GestioneLivelliBloc>(
          create:
              (_) =>
                  sl<GestioneLivelliBloc>()
                    ..add(const UtentiRichiesti(cerca: '')),
        ),
      ],
      child: _NuovaPartitaAdminView(slotIniziale: slotIniziale),
    );
  }
}

class _NuovaPartitaAdminView extends StatefulWidget {
  final SlotOrario? slotIniziale;

  const _NuovaPartitaAdminView({required this.slotIniziale});

  @override
  State<_NuovaPartitaAdminView> createState() => _NuovaPartitaAdminViewState();
}

class _NuovaPartitaAdminViewState extends State<_NuovaPartitaAdminView> {
  final TextEditingController _cercaController = TextEditingController();
  Timer? _debounce;

  SlotOrario? _slotScelto;
  // null finche' l'admin non sceglie: non c'e' un tipo giusto a priori
  String? _tipo;
  final List<UtenteAdmin> _utenti = [];
  int _giocatoriCampo = 0;

  // se lo slot passato dalla home nel frattempo e' stato preso, lo toglie
  // _controllaSlotScelto appena arrivano gli slot del giorno
  @override
  void initState() {
    super.initState();
    _slotScelto = widget.slotIniziale;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cercaController.dispose();
    super.dispose();
  }

  // a ogni lettera ripartiamo da capo con il timer: la richiesta parte solo
  // quando l'utente smette di scrivere per 400 ms
  void _onCercaCambiata(String testo) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) {
        return;
      }
      context.read<GestioneLivelliBloc>().add(
        UtentiRichiesti(cerca: testo.trim()),
      );
    });
  }

  void _ricaricaUtenti() {
    context.read<GestioneLivelliBloc>().add(
      UtentiRichiesti(cerca: _cercaController.text.trim()),
    );
  }

  int get _postiOccupati => _utenti.length + _giocatoriCampo;

  // i posti rimasti dopo gli utenti, ma il server ne accetta comunque al
  // massimo 3: l'utente obbligatorio lo si puo' aggiungere anche dopo
  int get _massimoGiocatoriCampo {
    final int rimasti = 4 - _utenti.length;
    return rimasti > 3 ? 3 : rimasti;
  }

  bool get _prontaPerCreare {
    return _slotScelto != null && _tipo != null && _utenti.isNotEmpty;
  }

  void _crea() {
    final SlotOrario? slot = _slotScelto;
    final String? tipo = _tipo;
    if (slot == null || tipo == null) {
      return;
    }

    final List<String> telefoni = [];
    for (final utente in _utenti) {
      telefoni.add(utente.telefono);
    }

    context.read<NuovaPartitaAdminBloc>().add(
      CreaPartitaAdminRichiesta(
        idCampo: slot.idCampo,
        data: context.read<PrenotaBloc>().state.giorno,
        oraInizio: slot.oraInizio,
        tipo: tipo,
        telefoni: telefoni,
        giocatoriCampo: _giocatoriCampo,
      ),
    );
  }

  // dopo un ricaricamento lo slot scelto puo' essere stato preso da qualcun
  // altro o essere gia' iniziato: in quel caso non va piu' proposto
  void _controllaSlotScelto(PrenotaState state) {
    final SlotOrario? scelto = _slotScelto;
    if (scelto == null || state is! PrenotaCaricato) {
      return;
    }

    final DateTime adesso = DateTime.now();
    bool ancoraLibero = false;
    final List<SlotOrario> slots = state.slotPerCampo[scelto.idCampo] ?? [];
    for (final slot in slots) {
      if (slot.oraInizio == scelto.oraInizio &&
          slot.disponibile &&
          !state.slotPassato(slot, adesso)) {
        ancoraLibero = true;
      }
    }

    if (!ancoraLibero) {
      setState(() {
        _slotScelto = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: Colori.sfondo,
      body: SafeArea(
        child: ContenutoCentrato(
          child: BlocConsumer<NuovaPartitaAdminBloc, NuovaPartitaAdminState>(
            listener: (context, state) {
              if (state is PartitaAdminCreata) {
                mostraSnackBar(context, 'Partita creata');
                Navigator.pushReplacement<void, void>(
                  context,
                  MaterialPageRoute<void>(
                    builder:
                        (_) => DettaglioAdminPage(idPartita: state.dettaglio.id),
                  ),
                );
              }
              // il rifiuto puo' dipendere da uno slot appena occupato: il
              // tabellone va riallineato con il server
              if (state is NuovaPartitaAdminErrore) {
                context.read<PrenotaBloc>().add(const PrenotaRichiesta());
              }
            },
            builder: (context, state) {
              final bool isLoading = state is NuovaPartitaAdminLoading;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TestataIndietro(titolo: 'Nuova partita'),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      // durante la creazione le scelte restano ferme
                      child: IgnorePointer(
                        ignoring: isLoading,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSlot(r),
                            const SizedBox(height: 16),
                            _buildTipo(r),
                            const SizedBox(height: 16),
                            _buildGiocatori(r),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildAzioni(state, isLoading),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _titoloSezione(Responsive r, String testo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(testo, style: stileTesto(r, base: 16, peso: FontWeight.w700)),
    );
  }

  // ===== CAMPO, GIORNO E SLOT =====

  Widget _buildSlot(Responsive r) {
    return BlocConsumer<PrenotaBloc, PrenotaState>(
      listener: (context, state) {
        _controllaSlotScelto(state);
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _titoloSezione(r, 'Campo e orario'),
            BarraGiorni(
              state: state,
              onGiornoScelto: (giorno) {
                setState(() {
                  _slotScelto = null;
                });
                context.read<PrenotaBloc>().add(
                  PrenotaGiornoCambiato(giorno: giorno),
                );
              },
            ),
            const SizedBox(height: 12),
            TabelloneSlot(
              state: state,
              slotScelto: _slotScelto,
              onSlotCambiato: (slot) {
                setState(() {
                  _slotScelto = slot;
                });
              },
            ),
            const SizedBox(height: 8),
            Text(_testoScelta(state), style: stileSecondario(r)),
          ],
        );
      },
    );
  }

  String _testoScelta(PrenotaState state) {
    final SlotOrario? slot = _slotScelto;
    if (slot == null) {
      return 'Tocca uno slot libero per sceglierlo';
    }
    return '${slot.nomeCampo}, ${dataEstesa(state.giorno)}, '
        '${oraBreve(slot.oraInizio)} - ${oraBreve(slot.oraFine)}';
  }

  // ===== TIPO =====

  Widget _buildTipo(Responsive r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _titoloSezione(r, 'Tipo di partita'),
        Row(
          children: [
            Expanded(child: _opzioneTipo(r, 'PUBBLICA', 'Pubblica')),
            const SizedBox(width: 8),
            Expanded(child: _opzioneTipo(r, 'PRIVATA', 'Privata')),
          ],
        ),
      ],
    );
  }

  Widget _opzioneTipo(Responsive r, String tipo, String testo) {
    final bool scelto = _tipo == tipo;

    return Semantics(
      selected: scelto,
      child: Material(
        color: scelto ? Colori.primario : Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: scelto ? BorderSide.none : const BorderSide(color: Colori.bordo),
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _tipo = tipo;
            });
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            child: Text(
              testo,
              style: stileTesto(
                r,
                peso: FontWeight.w700,
                colore: scelto ? Colors.white : Colori.testo,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== GIOCATORI =====

  Widget _buildGiocatori(Responsive r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _titoloSezione(r, 'Giocatori, $_postiOccupati su 4'),
        _buildUtentiScelti(r),
        const SizedBox(height: 12),
        _buildGiocatoriCampo(r),
        const SizedBox(height: 16),
        CampoRicerca(
          controller: _cercaController,
          onChanged: _onCercaCambiata,
        ),
        const SizedBox(height: 12),
        BlocBuilder<GestioneLivelliBloc, GestioneLivelliState>(
          builder: (context, stato) {
            return _buildRicerca(r, stato);
          },
        ),
      ],
    );
  }

  Widget _buildUtentiScelti(Responsive r) {
    final List<Widget> figli = [];
    for (final utente in _utenti) {
      if (figli.isNotEmpty) {
        figli.add(const Divider(height: 1, color: Colori.bordo));
      }
      figli.add(
        _rigaUtente(
          r,
          utente,
          LinkTesto(
            testo: 'Rimuovi',
            colore: Colori.rosso,
            onPressed: () {
              setState(() {
                _utenti.remove(utente);
              });
            },
          ),
        ),
      );
    }
    if (figli.isEmpty) {
      figli.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Scegli almeno un utente dalla ricerca qui sotto',
            style: stileSecondario(r),
          ),
        ),
      );
    }

    return CardBianca(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: figli,
      ),
    );
  }

  Widget _rigaUtente(Responsive r, UtenteAdmin utente, Widget azione) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${utente.nome} ${utente.cognome}',
                    style: stileTesto(r, peso: FontWeight.w600),
                  ),
                  Text(
                    'Livello ${utente.livello}',
                    style: stileSecondario(r, base: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            azione,
          ],
        ),
      ),
    );
  }

  Widget _buildGiocatoriCampo(Responsive r) {
    final bool puoTogliere = _giocatoriCampo > 0;
    final bool puoAggiungere = _giocatoriCampo < _massimoGiocatoriCampo;

    return CardBianca(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Giocatori del campo',
              style: stileTesto(r, peso: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Togli un giocatore del campo',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            padding: EdgeInsets.zero,
            color: Colori.bluCampo,
            disabledColor: Colori.grigio,
            icon: const Icon(Icons.remove_circle_outline),
            onPressed:
                puoTogliere
                    ? () {
                      setState(() {
                        _giocatoriCampo--;
                      });
                    }
                    : null,
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$_giocatoriCampo',
              textAlign: TextAlign.center,
              style: stileNumero(r, 18),
            ),
          ),
          IconButton(
            tooltip: 'Aggiungi un giocatore del campo',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            padding: EdgeInsets.zero,
            color: Colori.bluCampo,
            disabledColor: Colori.grigio,
            icon: const Icon(Icons.add_circle_outline),
            onPressed:
                puoAggiungere
                    ? () {
                      setState(() {
                        _giocatoriCampo++;
                      });
                    }
                    : null,
          ),
        ],
      ),
    );
  }

  // ===== RICERCA =====

  Widget _buildRicerca(Responsive r, GestioneLivelliState stato) {
    if (stato is UtentiErrore) {
      return CardErrore(
        titolo: 'Non siamo riusciti a caricare gli utenti',
        testo: stato.messaggio,
        onRiprova: _ricaricaUtenti,
      );
    }
    if (stato is UtentiCaricati) {
      return _buildRisultati(r, stato.utenti);
    }
    return const BarraGrigia(altezza: 120, raggio: 20);
  }

  bool _giaScelto(UtenteAdmin utente) {
    for (final scelto in _utenti) {
      if (scelto.telefono == utente.telefono) {
        return true;
      }
    }
    return false;
  }

  Widget _buildRisultati(Responsive r, List<UtenteAdmin> utenti) {
    final List<Widget> figli = [];
    for (final utente in utenti) {
      // chi e' gia' tra i giocatori non va proposto una seconda volta
      if (_giaScelto(utente)) {
        continue;
      }
      if (figli.isNotEmpty) {
        figli.add(const Divider(height: 1, color: Colori.bordo));
      }
      figli.add(
        _rigaUtente(
          r,
          utente,
          LinkTesto(
            testo: 'Aggiungi',
            onPressed:
                _postiOccupati >= 4
                    ? null
                    : () {
                      setState(() {
                        _utenti.add(utente);
                      });
                    },
          ),
        ),
      );
    }
    if (figli.isEmpty) {
      figli.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('Nessun utente trovato', style: stileSecondario(r)),
        ),
      );
    }

    return CardBianca(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: figli,
      ),
    );
  }

  // ===== AZIONI =====

  Widget _buildAzioni(NuovaPartitaAdminState state, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state is NuovaPartitaAdminErrore) ...[
            RiquadroMessaggio(testo: state.messaggio),
            const SizedBox(height: 8),
          ],
          BottonePieno(
            testo: 'Crea partita',
            altezza: 52,
            baseFont: 16,
            inCaricamento: isLoading,
            onPressed: _prontaPerCreare ? _crea : null,
          ),
        ],
      ),
    );
  }
}
