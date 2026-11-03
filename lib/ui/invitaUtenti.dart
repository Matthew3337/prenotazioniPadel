import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/invitaUtenti/invitaUtentiBloc.dart';
import 'package:thepadel/bloc/invitaUtenti/invitaUtentiEvent.dart';
import 'package:thepadel/bloc/invitaUtenti/invitaUtentiState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/utenteInvitabile.dart';

import 'campoPadel.dart';
import 'stileApp.dart';

class InvitaUtentiPage extends StatelessWidget {
  final int idPartita;
  // serve a scrivere data e campo in testata: il bloc di questa pagina non li da'
  final DettaglioPartita? dettaglio;

  const InvitaUtentiPage({super.key, required this.idPartita, this.dettaglio});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InvitaUtentiBloc>(
      create:
          (_) =>
              sl<InvitaUtentiBloc>()
                ..add(InvitabiliRichiesti(idPartita: idPartita, cerca: '')),
      child: _InvitaUtentiView(idPartita: idPartita, dettaglio: dettaglio),
    );
  }
}

// la view e' uno StatefulWidget perche' deve tenere il controller della
// ricerca e il Timer del debounce
class _InvitaUtentiView extends StatefulWidget {
  final int idPartita;
  final DettaglioPartita? dettaglio;

  const _InvitaUtentiView({required this.idPartita, required this.dettaglio});

  @override
  State<_InvitaUtentiView> createState() => _InvitaUtentiViewState();
}

class _InvitaUtentiViewState extends State<_InvitaUtentiView> {
  final TextEditingController _cercaController = TextEditingController();
  Timer? _debounce;

  // non tutti gli stati portano i posti liberi, quindi teniamo l'ultimo
  // valore ricevuto; null finche' non arriva il primo caricamento
  int? _postiLiberi;

  // il bloc toglie dall'elenco chi e' appena stato invitato: li teniamo qui
  // per poterli mostrare ancora, con la scritta "Invitato"
  final List<UtenteInvitabile> _invitati = [];
  UtenteInvitabile? _inInvito;

  // arriva con l'invito che ha occupato l'ultimo posto
  DettaglioPartita? _dettaglioAggiornato;

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
      // gli invitati li filtra la pagina: vanno ridisegnati col testo nuovo
      setState(() {});
      context.read<InvitaUtentiBloc>().add(
        InvitabiliRichiesti(idPartita: widget.idPartita, cerca: testo.trim()),
      );
    });
  }

  void _ricarica() {
    context.read<InvitaUtentiBloc>().add(
      InvitabiliRichiesti(
        idPartita: widget.idPartita,
        cerca: _cercaController.text.trim(),
      ),
    );
  }

  String _titoloTestata() {
    final DettaglioPartita? dettaglio = widget.dettaglio;
    if (dettaglio == null) {
      return 'Invita giocatori';
    }
    final String giorno = conMaiuscola(giornoRelativo(dettaglio.dataPartita));
    return '$giorno alle ${formattaOra(dettaglio.oraInizio)}, ${dettaglio.nomeCampo}';
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
              // true dice alla pagina precedente di ricaricarsi
              TestataIndietro(
                titolo: _titoloTestata(),
                onIndietro: () {
                  Navigator.pop(context, true);
                },
              ),
              Expanded(
                child: BlocConsumer<InvitaUtentiBloc, InvitaUtentiState>(
                  listener: (context, state) {
                    if (state is InvitabiliCaricati) {
                      setState(() {
                        _postiLiberi = state.postiLiberi;
                      });
                    }
                    if (state is InvitoInCorso) {
                      for (final utente in state.utenti) {
                        if (utente.telefono == state.telefono) {
                          _inInvito = utente;
                        }
                      }
                    }
                    if (state is InvitoRiuscito) {
                      setState(() {
                        _postiLiberi = state.postiLiberi;
                        _dettaglioAggiornato = state.dettaglio;
                        final UtenteInvitabile? invitato = _inInvito;
                        if (invitato != null) {
                          _invitati.add(invitato);
                        }
                      });
                      mostraSnackBar(context, 'Utente invitato');
                    }
                    // dopo l'errore il BLoC ricarica la lista da solo,
                    // qui basta avvisare l'utente
                    if (state is InvitoErrore) {
                      mostraSnackBar(context, state.messaggio);
                    }
                  },
                  builder: (context, state) {
                    if (state is InvitabiliCaricati && state.alCompleto) {
                      return _buildCompleta(context, r);
                    }
                    if (state is InvitoRiuscito && state.alCompleto) {
                      return _buildCompleta(context, r);
                    }
                    return _buildRicercaELista(context, r, state);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== RICERCA E LISTA =====

  // Il campo di ricerca sta sempre nello stesso punto dell'albero: Flutter lo
  // riusa a ogni stato e la tastiera non si chiude mentre arriva la lista.
  Widget _buildRicercaELista(
    BuildContext context,
    Responsive r,
    InvitaUtentiState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: _buildTitolo(r),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _buildRicerca(r),
        ),
        Expanded(child: _buildCorpo(context, r, state)),
      ],
    );
  }

  Widget _buildTitolo(Responsive r) {
    final int invitati = _invitati.length;
    final int? liberi = _postiLiberi;

    final List<String> parti = [];
    if (liberi == 1) {
      parti.add('Resta 1 posto libero');
    } else if (liberi != null) {
      parti.add('Restano $liberi posti liberi');
    }
    if (invitati == 1) {
      parti.add('1 invito inviato');
    } else if (invitati > 1) {
      parti.add('$invitati inviti inviati');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invita giocatori', style: stileTitolo(r)),
        const SizedBox(height: 4),
        if (liberi == null)
          const BarraGrigia(larghezza: 200, altezza: 16)
        else
          Text(parti.join(' · '), style: stileSecondario(r)),
      ],
    );
  }

  Widget _buildRicerca(Responsive r) {
    const OutlineInputBorder bordo = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Colori.grigio),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cerca per nome', style: stileTesto(r, peso: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: _cercaController,
          onChanged: _onCercaCambiata,
          textInputAction: TextInputAction.search,
          style: stileTesto(r),
          decoration: InputDecoration(
            hintText: 'Nome o cognome',
            hintStyle: stileSecondario(r),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: bordo,
            enabledBorder: bordo,
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: Colori.azzurro, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorpo(
    BuildContext context,
    Responsive r,
    InvitaUtentiState state,
  ) {
    if (state is InvitabiliErrore) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: CardErrore(
          titolo: 'Non siamo riusciti a caricare i giocatori',
          testo: state.messaggio,
          onRiprova: _ricarica,
        ),
      );
    }
    if (state is InvitabiliCaricati) {
      return _buildLista(context, r, state.utenti, null);
    }
    // durante l'invito la lista resta a schermo e solo il bottone dell'utente
    // scelto mostra lo spinner
    if (state is InvitoInCorso) {
      return _buildLista(context, r, state.utenti, state.telefono);
    }
    if (state is InvitoRiuscito) {
      return _buildLista(context, r, state.utenti, null);
    }
    if (state is InvitoErrore) {
      return _buildLista(context, r, state.utenti, null);
    }
    return _buildScheletro();
  }

  Widget _buildScheletro() {
    final List<Widget> righe = [];
    for (int i = 0; i < 6; i++) {
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

  bool _corrispondeAllaRicerca(UtenteInvitabile utente) {
    final String cerca = _cercaController.text.trim().toLowerCase();
    final String nome = '${utente.nome} ${utente.cognome}'.toLowerCase();
    return nome.contains(cerca);
  }

  Widget _buildLista(
    BuildContext context,
    Responsive r,
    List<UtenteInvitabile> utenti,
    String? telefonoInInvito,
  ) {
    final List<Widget> righe = [];

    for (final utente in _invitati) {
      if (_corrispondeAllaRicerca(utente)) {
        righe.add(_buildRiga(context, r, utente, righe.length, true, null));
      }
    }
    for (final utente in utenti) {
      righe.add(
        _buildRiga(context, r, utente, righe.length, false, telefonoInInvito),
      );
    }

    final List<Widget> figli = [];
    for (int i = 0; i < righe.length; i++) {
      if (i > 0) {
        figli.add(const Divider(height: 1, color: Colori.bordo));
      }
      figli.add(righe[i]);
    }
    if (righe.isEmpty) {
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
    bool invitato,
    String? telefonoInInvito,
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

    Widget azione;
    if (invitato) {
      azione = Text(
        'Invitato',
        style: stileTesto(r, peso: FontWeight.w700, colore: Colori.verde),
      );
    } else if (telefonoInInvito == utente.telefono) {
      azione = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colori.bluCampo,
        ),
      );
    } else {
      azione = LinkTesto(
        testo: 'Invita',
        // un invito per volta: lo stato ne segue uno solo
        onPressed:
            telefonoInInvito != null
                ? null
                : () {
                  context.read<InvitaUtentiBloc>().add(
                    InvitoRichiesto(
                      idPartita: widget.idPartita,
                      telefono: utente.telefono,
                    ),
                  );
                },
      );
    }

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
          SizedBox(
            width: 76,
            child: Align(alignment: Alignment.centerRight, child: azione),
          ),
        ],
      ),
    );
  }

  // ===== PARTITA AL COMPLETO =====

  Widget _buildCompleta(BuildContext context, Responsive r) {
    // se l'ultimo posto l'ha preso qualcun altro i giocatori nuovi non li
    // conosciamo: meglio il campo senza nomi che uno con un posto libero falso
    List<PostoCampo> posti = [];
    final DettaglioPartita? aggiornato = _dettaglioAggiornato;
    final DettaglioPartita? iniziale = widget.dettaglio;
    if (aggiornato != null && aggiornato.postiLiberi == 0) {
      posti = postiDaDettaglio(aggiornato);
    } else if (iniziale != null && iniziale.postiLiberi == 0) {
      posti = postiDaDettaglio(iniziale);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('La partita è al completo', style: stileTitolo(r)),
          const SizedBox(height: 12),
          CardBianca(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CampoPadel(altezza: 158, posti: posti),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'I quattro posti sono occupati: non servono altri inviti.',
                        style: stileTesto(r, base: 16),
                      ),
                      const SizedBox(height: 12),
                      BottonePieno(
                        testo: 'Torna alla partita',
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
