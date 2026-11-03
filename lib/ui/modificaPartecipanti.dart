import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/dettaglioAdmin/dettaglioAdminBloc.dart';
import 'package:thepadel/bloc/dettaglioAdmin/dettaglioAdminEvent.dart';
import 'package:thepadel/bloc/dettaglioAdmin/dettaglioAdminState.dart';
import 'package:thepadel/bloc/gestioneLivelli/gestioneLivelliBloc.dart';
import 'package:thepadel/bloc/gestioneLivelli/gestioneLivelliEvent.dart';
import 'package:thepadel/bloc/gestioneLivelli/gestioneLivelliState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';
import 'package:thepadel/domainLayer/enetity/utenteAdmin.dart';

import 'stileApp.dart';

class ModificaPartecipantiPage extends StatelessWidget {
  final DettaglioPartita dettaglio;
  // il bloc della pagina di dettaglio: deve sapere dell'operazione per
  // mostrare i partecipanti nuovi quando si torna indietro
  final DettaglioAdminBloc bloc;

  const ModificaPartecipantiPage({
    super.key,
    required this.dettaglio,
    required this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DettaglioAdminBloc>.value(value: bloc),
        // questo invece e' solo della pagina e serve per la ricerca degli utenti
        BlocProvider<GestioneLivelliBloc>(
          create:
              (_) =>
                  sl<GestioneLivelliBloc>()
                    ..add(const UtentiRichiesti(cerca: '')),
        ),
      ],
      child: _ModificaPartecipantiView(dettaglio: dettaglio),
    );
  }
}

class _ModificaPartecipantiView extends StatefulWidget {
  final DettaglioPartita dettaglio;

  const _ModificaPartecipantiView({required this.dettaglio});

  @override
  State<_ModificaPartecipantiView> createState() =>
      _ModificaPartecipantiViewState();
}

class _ModificaPartecipantiViewState extends State<_ModificaPartecipantiView> {
  final TextEditingController _cercaController = TextEditingController();
  Timer? _debounce;

  // Le modifiche restano qui finche' non si tocca "Salva". I posti del campo
  // non cambiano mai: li teniamo a parte e li contiamo per il limite di 4.
  final List<PostoPartita> _utenti = [];
  final List<PostoPartita> _postiCampo = [];

  @override
  void initState() {
    super.initState();
    for (final posto in widget.dettaglio.posti) {
      if (posto.tipo == 'UTENTE') {
        _utenti.add(posto);
      } else {
        _postiCampo.add(posto);
      }
    }
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

  int get _postiOccupati => _utenti.length + _postiCampo.length;

  void _rimuovi(PostoPartita posto) {
    setState(() {
      _utenti.remove(posto);
    });
  }

  void _aggiungi(UtenteAdmin utente) {
    setState(() {
      _utenti.add(
        PostoPartita(
          idPosto: null,
          tipo: 'UTENTE',
          telefono: utente.telefono,
          nome: utente.nome,
          cognome: utente.cognome,
          livello: utente.livello,
          confermata: false,
          squadra: null,
        ),
      );
    });
  }

  void _salva() {
    final List<String> telefoni = [];
    for (final posto in _utenti) {
      final String? telefono = posto.telefono;
      if (telefono != null) {
        telefoni.add(telefono);
      }
    }
    context.read<DettaglioAdminBloc>().add(
      ModificaPartecipantiRichiesta(
        id: widget.dettaglio.id,
        telefoni: telefoni,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: Colori.sfondo,
      body: SafeArea(
        child: ContenutoCentrato(
          child: BlocConsumer<DettaglioAdminBloc, DettaglioAdminState>(
            listener: (context, state) {
              if (state is OperazioneAdminRiuscita) {
                mostraSnackBar(context, state.messaggio);
                Navigator.pop(context);
              }
              if (state is OperazioneAdminErrore) {
                mostraSnackBar(context, state.messaggio);
              }
            },
            builder: (context, state) {
              final bool isLoading = state is OperazioneAdminInCorso;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TestataIndietro(titolo: 'Modifica partecipanti'),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Giocatori, $_postiOccupati su 4',
                            style: stileTitolo(r),
                          ),
                          const SizedBox(height: 12),
                          _buildPartecipanti(r, isLoading),
                          const SizedBox(height: 16),
                          CampoRicerca(
                            controller: _cercaController,
                            onChanged: _onCercaCambiata,
                          ),
                          const SizedBox(height: 12),
                          BlocBuilder<
                            GestioneLivelliBloc,
                            GestioneLivelliState
                          >(
                            builder: (context, statoRicerca) {
                              return _buildRicerca(r, statoRicerca, isLoading);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: BottonePieno(
                      testo: 'Salva',
                      altezza: 52,
                      baseFont: 16,
                      inCaricamento: isLoading,
                      onPressed: _salva,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ===== PARTECIPANTI =====

  Widget _buildPartecipanti(Responsive r, bool isLoading) {
    final List<Widget> righe = [];
    for (final posto in _utenti) {
      righe.add(_rigaUtente(r, posto, isLoading));
    }
    for (int i = 0; i < _postiCampo.length; i++) {
      righe.add(
        _rigaPartecipante(
          r,
          nome: 'Giocatore del campo',
          dettagli: null,
          azione: null,
        ),
      );
    }

    final List<Widget> figli = [];
    for (int i = 0; i < righe.length; i++) {
      if (i > 0) {
        figli.add(const Divider(height: 1, color: Colori.bordo));
      }
      figli.add(righe[i]);
    }

    return CardBianca(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: figli,
      ),
    );
  }

  Widget _rigaUtente(Responsive r, PostoPartita posto, bool isLoading) {
    Widget azione;
    if (posto.telefono == widget.dettaglio.telefonoCreatore) {
      azione = const Pillola(
        testo: 'Organizzatore',
        sfondo: Colori.azzurroChiaro,
        colore: Colori.azzurro,
      );
    } else {
      azione = LinkTesto(
        testo: 'Rimuovi',
        colore: Colori.rosso,
        onPressed:
            isLoading
                ? null
                : () {
                  _rimuovi(posto);
                },
      );
    }

    return _rigaPartecipante(
      r,
      nome: '${posto.nome ?? ''} ${posto.cognome ?? ''}'.trim(),
      dettagli: posto.livello == null ? null : 'Livello ${posto.livello}',
      azione: azione,
    );
  }

  Widget _rigaPartecipante(
    Responsive r, {
    required String nome,
    required String? dettagli,
    required Widget? azione,
  }) {
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
                  Text(nome, style: stileTesto(r, peso: FontWeight.w600)),
                  if (dettagli != null)
                    Text(dettagli, style: stileSecondario(r, base: 13)),
                ],
              ),
            ),
            if (azione != null) ...[const SizedBox(width: 8), azione],
          ],
        ),
      ),
    );
  }

  // ===== RICERCA =====

  Widget _buildRicerca(
    Responsive r,
    GestioneLivelliState stato,
    bool isLoading,
  ) {
    if (stato is UtentiErrore) {
      return CardErrore(
        titolo: 'Non siamo riusciti a caricare gli utenti',
        testo: stato.messaggio,
        onRiprova: _ricaricaUtenti,
      );
    }
    if (stato is UtentiCaricati) {
      return _buildRisultati(r, stato.utenti, isLoading);
    }
    return const BarraGrigia(altezza: 120, raggio: 20);
  }

  bool _giaPartecipa(UtenteAdmin utente) {
    for (final posto in _utenti) {
      if (posto.telefono == utente.telefono) {
        return true;
      }
    }
    return false;
  }

  Widget _buildRisultati(
    Responsive r,
    List<UtenteAdmin> utenti,
    bool isLoading,
  ) {
    final List<Widget> figli = [];
    for (final utente in utenti) {
      // chi e' gia' tra i partecipanti non va proposto una seconda volta
      if (_giaPartecipa(utente)) {
        continue;
      }
      if (figli.isNotEmpty) {
        figli.add(const Divider(height: 1, color: Colori.bordo));
      }
      figli.add(
        _rigaPartecipante(
          r,
          nome: '${utente.nome} ${utente.cognome}',
          dettagli: 'Livello ${utente.livello}',
          azione: LinkTesto(
            testo: 'Aggiungi',
            onPressed:
                isLoading || _postiOccupati >= 4
                    ? null
                    : () {
                      _aggiungi(utente);
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
}
