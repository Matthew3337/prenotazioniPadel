import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/creaPartita/creaPartitaBloc.dart';
import 'package:thepadel/bloc/creaPartita/creaPartitaEvent.dart';
import 'package:thepadel/bloc/creaPartita/creaPartitaState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';

import 'barraNavigazione.dart';
import 'campoPadel.dart';
import 'prenota.dart';
import 'stileApp.dart';

class CreaPartitaPage extends StatelessWidget {
  final SlotOrario slot;
  final DateTime data;
  // lo slot non sa se il campo e' al coperto: lo passa solo chi lo conosce
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
      child: _CreaPartitaView(slot: slot, data: data, alCoperto: alCoperto),
    );
  }
}

class _CreaPartitaView extends StatefulWidget {
  final SlotOrario slot;
  final DateTime data;
  final bool? alCoperto;

  const _CreaPartitaView({
    required this.slot,
    required this.data,
    required this.alCoperto,
  });

  @override
  State<_CreaPartitaView> createState() => _CreaPartitaViewState();
}

class _CreaPartitaViewState extends State<_CreaPartitaView> {
  late SlotOrario _slot;
  bool? _alCoperto;

  // stringa vuota finche' l'utente non sceglie: e' il BLoC a segnalare
  // l'errore se si preme "Prenota il campo" senza aver scelto
  String _tipoScelto = '';

  // finche' c'e' questo stato si mostra la pagina "slot non disponibile";
  // toccando un'alternativa si torna al riepilogo con il nuovo slot
  CreaPartitaSlotPreso? _slotPreso;

  // l'errore resta sopra il bottone finche' non si riprova
  String? _errore;

  @override
  void initState() {
    super.initState();
    _slot = widget.slot;
    _alCoperto = widget.alCoperto;
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
                // restituiamo l'id a chi ha aperto la pagina: e' lui ad aprire
                // il dettaglio, cosi' al ritorno puo' ricaricarsi di nuovo
                Navigator.pop(context, state.prenotazione.id);
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

  // ===== RIEPILOGO =====

  Widget _buildRiepilogo(BuildContext context, Responsive r, bool isLoading) {
    final String giorno = conMaiuscola(giornoRelativo(widget.data));
    String sottotitolo =
        '${conMaiuscola(dataEstesa(widget.data))}, ${_fasciaOraria()}';
    if (_alCoperto == true) {
      sottotitolo += ' · Al coperto';
    }
    if (_alCoperto == false) {
      sottotitolo += " · All'aperto";
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
                  '$giorno alle ${oraBreve(_slot.oraInizio)}, ${_slot.nomeCampo}',
                  style: stileTitolo(r),
                ),
                const SizedBox(height: 4),
                Text(sottotitolo, style: stileSecondario(r)),
                const SizedBox(height: 16),
                const CampoPadel(
                  altezza: 180,
                  dimensionePosto: 48,
                  arrotondato: true,
                  posti: [
                    PostoCampo(
                      iniziali: 'Tu',
                      sfondo: Colori.azzurroChiaro,
                      colore: Colori.azzurro,
                      descrizione: 'Tu',
                    ),
                    PostoCampo.vuoto(),
                    PostoCampo.vuoto(),
                    PostoCampo.vuoto(),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chi può occupare i tre posti liberi?',
                  style: stileTesto(r, base: 16, peso: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _buildOpzione(
                  r,
                  isLoading,
                  tipo: 'PUBBLICA',
                  titolo: 'Partita pubblica',
                  testo:
                      'Visibile in bacheca agli utenti di livello simile al tuo',
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
                onPressed: () {
                  setState(() {
                    _errore = null;
                  });
                  context.read<CreaPartitaBloc>().add(
                    CreaPartitaRichiesta(
                      slot: _slot,
                      data: widget.data,
                      tipo: _tipoScelto,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
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
                    setState(() {
                      _tipoScelto = tipo;
                      _errore = null;
                    });
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
              // si resta sulla stessa pagina con lo slot nuovo: chi l'ha
              // aperta continua ad aspettare l'id della partita da qui.
              // Il tipo si sceglie di nuovo, e non sappiamo se questo campo
              // e' al coperto
              setState(() {
                _slot = slot;
                _alCoperto = null;
                _slotPreso = null;
                _tipoScelto = '';
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
