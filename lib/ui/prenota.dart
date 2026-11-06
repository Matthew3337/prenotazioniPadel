import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/prenota/prenotaBloc.dart';
import 'package:thepadel/bloc/prenota/prenotaEvent.dart';
import 'package:thepadel/bloc/prenota/prenotaState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';

import 'barraNavigazione.dart';
import 'creaPartita.dart';
import 'dettaglioPartita.dart';
import 'home.dart';
import 'stileApp.dart';
import 'tabelloneSlot.dart';

class PrenotaPage extends StatelessWidget {
  // da "Vedi tutti gli orari" si arriva qui con il giorno gia' scelto
  final DateTime? giornoIniziale;

  const PrenotaPage({super.key, this.giornoIniziale});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PrenotaBloc>(
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
      child: const _PrenotaView(),
    );
  }
}

class _PrenotaView extends StatefulWidget {
  const _PrenotaView();

  @override
  State<_PrenotaView> createState() => _PrenotaViewState();
}

class _PrenotaViewState extends State<_PrenotaView> {
  // lo slot toccato e non ancora confermato con "Continua"
  SlotOrario? _slotScelto;

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: Colori.sfondo,
      bottomNavigationBar: const BarraNavigazione(
        voceAttiva: VoceBarra.prenota,
      ),
      body: SafeArea(
        child: ContenutoCentrato(
          child: BlocBuilder<PrenotaBloc, PrenotaState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Prenota un campo', style: stileTitolo(r)),
                          const SizedBox(height: 12),
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
                            onApriPartita: (idPartita) {
                              _apriDettaglio(context, idPartita);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // resta fuori dallo scorrimento: il tabellone puo' essere
                  // lungo e "Continua" deve vedersi subito dopo il tocco
                  if (_slotScelto != null && state is PrenotaCaricato)
                    _buildScelta(context, r, state, _slotScelto!),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ===== SCELTA =====

  Widget _buildScelta(
    BuildContext context,
    Responsive r,
    PrenotaCaricato state,
    SlotOrario slot,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: CardBianca(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${slot.nomeCampo}, ${nomeGiorno(state.giorno)} ${state.giorno.day}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: stileTesto(r, peso: FontWeight.w700),
                  ),
                  Text(
                    '${oraBreve(slot.oraInizio)} - ${oraBreve(slot.oraFine)}',
                    style: stileSecondario(r, base: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            BottonePieno(
              testo: 'Continua',
              onPressed: () {
                _apriCreaPartita(context, state, slot);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===== NAVIGAZIONE =====

  Future<void> _apriCreaPartita(
    BuildContext context,
    PrenotaCaricato state,
    SlotOrario slot,
  ) async {
    bool? alCoperto;
    for (final campo in state.campi) {
      if (campo.id == slot.idCampo) {
        alCoperto = campo.alCoperto;
      }
    }

    final int? idPartita = await Navigator.push<int>(
      context,
      MaterialPageRoute<int>(
        builder:
            (_) => CreaPartitaPage(
              slot: slot,
              data: state.giorno,
              alCoperto: alCoperto,
            ),
      ),
    );

    // a partita creata si torna sempre in home, che mostra la nuova partita
    if (idPartita != null && context.mounted) {
      tornaAllaVoce(context, const HomePage());
    }
  }

  Future<void> _apriDettaglio(BuildContext context, int idPartita) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => DettaglioPartitaPage(idPartita: idPartita),
      ),
    );

    if (context.mounted) {
      context.read<PrenotaBloc>().add(const PrenotaRichiesta());
    }
  }
}
