import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/cercaInvitati/cercaInvitatiBloc.dart';
import 'package:thepadel/bloc/cercaInvitati/cercaInvitatiEvent.dart';
import 'package:thepadel/bloc/cercaInvitati/cercaInvitatiState.dart';
import 'package:thepadel/bloc/creaPartita/creaPartitaBloc.dart';
import 'package:thepadel/bloc/creaPartita/creaPartitaEvent.dart';
import 'package:thepadel/bloc/creaPartita/creaPartitaState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';
import 'package:thepadel/domainLayer/enetity/utenteInvitabile.dart';

import 'barraNavigazione.dart';
import 'campoPadel.dart';
import 'home.dart';
import 'prenota.dart';
import 'stileApp.dart';

class CreaPartitaPage extends StatelessWidget {
  final SlotOrario slot;
  final DateTime data;
  // il riepilogo non scrive piu' se il campo e' al coperto: il parametro
  // resta solo perche' chi apre la pagina lo passa ancora
  final bool? alCoperto;

  const CreaPartitaPage({
    super.key,
    required this.slot,
    required this.data,
    this.alCoperto,
  });

  @override
  Widget build(BuildContext context) {
    // nessun evento iniziale: la richiesta parte solo quando l'utente
    // tocca "Prenota il campo"
    return BlocProvider<CreaPartitaBloc>(
      create: (_) => sl<CreaPartitaBloc>(),
      child: _CreaPartitaView(slot: slot, data: data),
    );
  }
}

class _CreaPartitaView extends StatefulWidget {
  final SlotOrario slot;
  final DateTime data;

  const _CreaPartitaView({required this.slot, required this.data});

  @override
  State<_CreaPartitaView> createState() => _CreaPartitaViewState();
}

class _CreaPartitaViewState extends State<_CreaPartitaView> {
  // quanto dura il passaggio dai due bottoni del tipo al campo
  static const Duration _durataTransizione = Duration(milliseconds: 300);

  late SlotOrario _slot;

  // stringa vuota finche' l'utente non sceglie pubblica o privata
  String _tipoScelto = '';

  // diventa true solo a transizione finita: fino ad allora "Prenota il
  // campo" resta spento
  bool _campoVisibile = false;

  // gli utenti scelti per i tre posti liberi; partono con la prenotazione
  final List<UtenteInvitabile> _invitati = [];

  // finche' c'e' questo stato si mostra la pagina "slot non disponibile";
  // toccando un'alternativa si torna al riepilogo con il nuovo slot
  CreaPartitaSlotPreso? _slotPreso;

  // l'errore resta sopra il bottone finche' non si riprova
  String? _errore;

  @override
  void initState() {
    super.initState();
    _slot = widget.slot;
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: Colori.sfondo,
      body: SafeArea(
        child: ContenutoCentrato(
          child: BlocConsumer<CreaPartitaBloc, CreaPartitaState>(
            listener: (context, state) {
              if (state is CreaPartitaSuccess) {
                mostraSnackBar(context, 'Partita creata');
                // si torna sempre alla home, anche se il riepilogo e' stato
                // aperto dalla pagina Prenota: la home nuova si carica da sola
                tornaAllaVoce(context, const HomePage());
              }
              // CreaPartitaSlotPreso e' anche un CreaPartitaErrore, quindi
              // va controllato per primo
              if (state is CreaPartitaSlotPreso) {
                setState(() {
                  _slotPreso = state;
                  _errore = null;
                });
              } else if (state is CreaPartitaErrore) {
                setState(() {
                  _errore = state.messaggio;
                });
              }
            },
            builder: (context, state) {
              final bool isLoading = state is CreaPartitaLoading;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TestataIndietro(titolo: 'Riepilogo partita'),
                  Expanded(
                    child:
                        _slotPreso != null
                            ? _buildSlotPreso(context, r, _slotPreso!)
                            : _buildRiepilogo(context, r, isLoading),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _fasciaOraria() {
    return '${oraBreve(_slot.oraInizio)} - ${oraBreve(_slot.oraFine)}';
  }

  void _scegliTipo(String tipo) {
    setState(() {
      _tipoScelto = tipo;
      _errore = null;
    });
    // il bottone si accende quando il campo ha finito di comparire
    Future.delayed(_durataTransizione, () {
      if (mounted) {
        setState(() {
          _campoVisibile = true;
        });
      }
    });
  }

  // ===== RIEPILOGO =====

  Widget _buildRiepilogo(BuildContext context, Responsive r, bool isLoading) {
    final String titolo =
        '${conMaiuscola(dataEstesa(widget.data))}, ${_fasciaOraria()}, '
        '${_slot.nomeCampo}';

    // la chiave dice all'AnimatedSwitcher che il contenuto e' cambiato
    Widget sceltaOCampo;
    if (_tipoScelto == '') {
      sceltaOCampo = Column(
        key: const ValueKey('scelta'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildOpzione(
            r,
            isLoading,
            tipo: 'PUBBLICA',
            titolo: 'Partita pubblica',
            testo: 'Visibile in bacheca agli utenti di livello simile al tuo',
          ),
          const SizedBox(height: 8),
          _buildOpzione(
            r,
            isLoading,
            tipo: 'PRIVATA',
            titolo: 'Partita privata',
            testo: 'Entra solo chi inviti tu',
          ),
        ],
      );
    } else {
      sceltaOCampo = Column(
        key: const ValueKey('campo'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CampoPadel(
            altezza: 200,
            dimensionePosto: 48,
            arrotondato: true,
            posti: _postiDelCampo(context, isLoading),
          ),
          if (_invitati.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildInvitati(r, isLoading),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(titolo, style: stileTitolo(r)),
                const SizedBox(height: 16),
                // AnimatedSize accompagna il cambio di altezza, cosi' la
                // pagina non salta mentre i bottoni lasciano il posto al campo
                AnimatedSize(
                  duration: _durataTransizione,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: _durataTransizione,
                    child: sceltaOCampo,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errore != null) ...[
                RiquadroMessaggio(testo: _errore!),
                const SizedBox(height: 8),
              ],
              BottonePieno(
                testo: 'Prenota il campo',
                altezza: 52,
                baseFont: 16,
                inCaricamento: isLoading,
                onPressed:
                    _campoVisibile
                        ? () {
                          _prenota(context);
                        }
                        : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _prenota(BuildContext context) {
    final List<String> telefoni = [];
    for (final utente in _invitati) {
      telefoni.add(utente.telefono);
    }
    setState(() {
      _errore = null;
    });
    context.read<CreaPartitaBloc>().add(
      CreaPartitaRichiesta(
        slot: _slot,
        data: widget.data,
        tipo: _tipoScelto,
        invitati: telefoni,
      ),
    );
  }

  Widget _buildOpzione(
    Responsive r,
    bool isLoading, {
    required String tipo,
    required String titolo,
    required String testo,
  }) {
    final bool scelta = _tipoScelto == tipo;

    return Semantics(
      selected: scelta,
      child: Material(
        color: scelta ? Colori.azzurroChiaro : Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: scelta ? Colori.primario : Colori.bordo,
            width: scelta ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap:
              isLoading
                  ? null
                  : () {
                    _scegliTipo(tipo);
                  },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scelta ? Colori.primario : Colori.grigio,
                      width: scelta ? 6 : 2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titolo,
                        style: stileTesto(r, base: 16, peso: FontWeight.w700),
                      ),
                      Text(testo, style: stileSecondario(r)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== CAMPO E INVITATI =====

  // il primo posto e' sempre di chi prenota, poi gli scelti e in fondo i
  // posti ancora liberi con il +
  List<PostoCampo> _postiDelCampo(BuildContext context, bool isLoading) {
    const List<Color> sfondi = [
      Colori.verdeChiaro,
      Colori.arancioChiaro,
      Colori.rossoChiaro,
    ];
    const List<Color> colori = [Colori.verde, Colori.arancio, Colori.rosso];

    final List<PostoCampo> posti = [
      const PostoCampo(
        iniziali: 'Tu',
        sfondo: Colori.azzurroChiaro,
        colore: Colori.azzurro,
        descrizione: 'Tu',
      ),
    ];
    for (int i = 0; i < _invitati.length; i++) {
      final UtenteInvitabile utente = _invitati[i];
      posti.add(
        PostoCampo(
          iniziali: inizialiDi(utente.nome, utente.cognome),
          sfondo: sfondi[i % sfondi.length],
          colore: colori[i % colori.length],
          nome: utente.nome,
          descrizione: '${utente.nome} ${utente.cognome}',
        ),
      );
    }
    for (int i = _invitati.length; i < 3; i++) {
      posti.add(
        PostoCampo.vuoto(
          nome: 'Invita',
          onTap:
              isLoading
                  ? null
                  : () {
                    _apriSceltaInvitato(context);
                  },
        ),
      );
    }
    return posti;
  }

  Widget _buildInvitati(Responsive r, bool isLoading) {
    final List<Widget> figli = [];
    for (int i = 0; i < _invitati.length; i++) {
      final UtenteInvitabile utente = _invitati[i];
      if (i > 0) {
        figli.add(const Divider(height: 1, color: Colori.bordo));
      }
      figli.add(
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
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
              LinkTesto(
                testo: 'Togli',
                colore: Colori.rosso,
                onPressed:
                    isLoading
                        ? null
                        : () {
                          setState(() {
                            _invitati.remove(utente);
                          });
                        },
              ),
            ],
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

  Future<void> _apriSceltaInvitato(BuildContext context) async {
    final List<String> giaScelti = [];
    for (final utente in _invitati) {
      giaScelti.add(utente.telefono);
    }

    final UtenteInvitabile? scelto = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colori.sfondo,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return BlocProvider<CercaInvitatiBloc>(
          create:
              (_) =>
                  sl<CercaInvitatiBloc>()
                    ..add(const CercaInvitatiRichiesta(cerca: '')),
          child: _SceltaInvitato(giaScelti: giaScelti),
        );
      },
    );

    // il controllo sul numero serve se nel frattempo i posti sono finiti
    if (scelto != null && mounted && _invitati.length < 3) {
      setState(() {
        _invitati.add(scelto);
      });
    }
  }

  // ===== SLOT NON PIU' DISPONIBILE =====

  Widget _buildSlotPreso(
    BuildContext context,
    Responsive r,
    CreaPartitaSlotPreso stato,
  ) {
    String titoloAlternative = 'Ancora liberi oggi';
    if (giornoRelativo(stato.data) != 'oggi') {
      titoloAlternative = 'Ancora liberi ${giornoRelativo(stato.data)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Questo slot non è più disponibile',
                  style: stileTitolo(r),
                ),
                const SizedBox(height: 4),
                Text(
                  '${conMaiuscola(dataEstesa(stato.data))}, '
                  '${_fasciaOraria()} · ${_slot.nomeCampo}',
                  style: stileSecondario(r),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colori.rossoChiaro,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(stato.messaggio, style: stileTesto(r, base: 16)),
                ),
                if (stato.slotLiberi.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  CardBianca(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          titoloAlternative,
                          style: stileTesto(r, base: 16, peso: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        ..._righeAlternative(r, stato.slotLiberi),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: BottonePieno(
            testo: 'Vedi tutti gli orari',
            altezza: 52,
            baseFont: 16,
            onPressed: () {
              tornaAllaVoce(
                context,
                PrenotaPage(giornoIniziale: stato.data),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _righeAlternative(Responsive r, List<SlotOrario> slots) {
    final List<Widget> righe = [];
    for (int i = 0; i < slots.length; i++) {
      final SlotOrario slot = slots[i];
      if (i > 0) {
        righe.add(const SizedBox(height: 8));
      }
      righe.add(
        Material(
          color: Colori.verdeChiaro,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () {
              // si resta sulla stessa pagina con lo slot nuovo: tipo e
              // invitati scelti restano quelli di prima, basta prenotare
              setState(() {
                _slot = slot;
                _slotPreso = null;
              });
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      slot.nomeCampo,
                      style: stileTesto(
                        r,
                        peso: FontWeight.w700,
                        colore: Colori.verde,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${oraBreve(slot.oraInizio)} - ${oraBreve(slot.oraFine)}',
                    style: stileTesto(
                      r,
                      peso: FontWeight.w700,
                      colore: Colori.verde,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return righe;
  }
}

// ===== SCELTA DI UN INVITATO =====

// Il foglio dal basso per cercare un utente: toccandone uno il foglio si
// chiude e lo restituisce alla pagina, che lo mette nel primo posto libero.
class _SceltaInvitato extends StatefulWidget {
  // i telefoni di chi e' gia' stato scelto: non vanno riproposti
  final List<String> giaScelti;

  const _SceltaInvitato({required this.giaScelti});

  @override
  State<_SceltaInvitato> createState() => _SceltaInvitatoState();
}

class _SceltaInvitatoState extends State<_SceltaInvitato> {
  final TextEditingController _cercaController = TextEditingController();
  Timer? _debounce;

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
      context.read<CercaInvitatiBloc>().add(
        CercaInvitatiRichiesta(cerca: testo.trim()),
      );
    });
  }

  void _ricarica() {
    context.read<CercaInvitatiBloc>().add(
      CercaInvitatiRichiesta(cerca: _cercaController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final MediaQueryData media = MediaQuery.of(context);

    // il foglio prende gran parte dello schermo e sale con la tastiera
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: media.size.height * 0.8,
        child: ContenutoCentrato(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Text('Invita un giocatore', style: stileNumero(r, 22)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: CampoRicerca(
                  controller: _cercaController,
                  onChanged: _onCercaCambiata,
                ),
              ),
              Expanded(
                child: BlocBuilder<CercaInvitatiBloc, CercaInvitatiState>(
                  builder: (context, state) {
                    if (state is CercaInvitatiErrore) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: CardErrore(
                          titolo: 'Non siamo riusciti a caricare i giocatori',
                          testo: state.messaggio,
                          onRiprova: _ricarica,
                        ),
                      );
                    }
                    if (state is CercaInvitatiCaricati) {
                      return _buildLista(context, r, state.utenti);
                    }
                    return _buildScheletro();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheletro() {
    final List<Widget> righe = [];
    for (int i = 0; i < 5; i++) {
      righe.add(
        const SizedBox(
          height: 60,
          child: Row(
            children: [
              BarraGrigia(larghezza: 40, altezza: 40, raggio: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BarraGrigia(larghezza: 140, altezza: 16),
                    SizedBox(height: 4),
                    BarraGrigia(larghezza: 70, altezza: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: CardBianca(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(children: righe),
      ),
    );
  }

  Widget _buildLista(
    BuildContext context,
    Responsive r,
    List<UtenteInvitabile> utenti,
  ) {
    // il bloc restituisce anche chi e' gia' stato scelto: lo togliamo qui
    final List<UtenteInvitabile> daMostrare = [];
    for (final utente in utenti) {
      if (!widget.giaScelti.contains(utente.telefono)) {
        daMostrare.add(utente);
      }
    }

    final List<Widget> figli = [];
    for (int i = 0; i < daMostrare.length; i++) {
      if (i > 0) {
        figli.add(const Divider(height: 1, color: Colori.bordo));
      }
      figli.add(_buildRiga(context, r, daMostrare[i], i));
    }
    if (daMostrare.isEmpty) {
      figli.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('Nessun utente trovato', style: stileSecondario(r)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: CardBianca(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: figli,
        ),
      ),
    );
  }

  Widget _buildRiga(
    BuildContext context,
    Responsive r,
    UtenteInvitabile utente,
    int indice,
  ) {
    const List<Color> sfondi = [
      Colori.azzurroChiaro,
      Colori.verdeChiaro,
      Colori.arancioChiaro,
      Colori.rossoChiaro,
    ];
    const List<Color> colori = [
      Colori.azzurro,
      Colori.verde,
      Colori.arancio,
      Colori.rosso,
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Row(
        children: [
          CerchioIniziali(
            testo: inizialiDi(utente.nome, utente.cognome),
            sfondo: sfondi[indice % sfondi.length],
            colore: colori[indice % colori.length],
            dimensione: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${utente.nome} ${utente.cognome}',
                  style: stileTesto(r, base: 16, peso: FontWeight.w600),
                ),
                Text(
                  'Livello ${utente.livello}',
                  style: stileSecondario(r, base: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          LinkTesto(
            testo: 'Invita',
            onPressed: () {
              Navigator.pop(context, utente);
            },
          ),
        ],
      ),
    );
  }
}
