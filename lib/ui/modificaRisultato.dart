import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/dettaglioAdmin/dettaglioAdminBloc.dart';
import 'package:thepadel/bloc/dettaglioAdmin/dettaglioAdminEvent.dart';
import 'package:thepadel/bloc/dettaglioAdmin/dettaglioAdminState.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';

import 'registraRisultato.dart';
import 'stileApp.dart';

class ModificaRisultatoPage extends StatelessWidget {
  final DettaglioPartita dettaglio;
  // il bloc della pagina di dettaglio: deve sapere dell'operazione per
  // mostrare il risultato nuovo quando si torna indietro
  final DettaglioAdminBloc bloc;

  const ModificaRisultatoPage({
    super.key,
    required this.dettaglio,
    required this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DettaglioAdminBloc>.value(
      value: bloc,
      child: _ModificaRisultatoView(dettaglio: dettaglio),
    );
  }
}

class _ModificaRisultatoView extends StatefulWidget {
  final DettaglioPartita dettaglio;

  const _ModificaRisultatoView({required this.dettaglio});

  @override
  State<_ModificaRisultatoView> createState() => _ModificaRisultatoViewState();
}

class _ModificaRisultatoViewState extends State<_ModificaRisultatoView> {
  // come nella pagina dell'utente l'errore sta sopra il bottone: una SnackBar
  // lo coprirebbe proprio mentre si vuole correggere e riprovare
  String? _errore;

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
                setState(() {
                  _errore = state.messaggio;
                });
              }
            },
            builder: (context, state) {
              final bool isLoading = state is OperazioneAdminInCorso;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TestataIndietro(
                    titolo: 'Modifica risultato, ${widget.dettaglio.nomeCampo}',
                  ),
                  Expanded(
                    child:
                        squadreComponibili(widget.dettaglio)
                            ? _buildForm(context, isLoading)
                            : _buildNonDisponibile(context, r),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isLoading) {
    return FormRisultato(
      dettaglio: widget.dettaglio,
      isLoading: isLoading,
      errore: _errore,
      onCambiato: () {
        setState(() {
          _errore = null;
        });
      },
      onSalva: (squadra1, squadra2, set) {
        context.read<DettaglioAdminBloc>().add(
          ModificaRisultatoRichiesta(
            id: widget.dettaglio.id,
            squadra1: squadra1,
            squadra2: squadra2,
            set: set,
          ),
        );
      },
    );
  }

  // l'admin puo' mettere a mano una partita in stato confermata anche se non
  // e' al completo: senza quattro giocatori non si possono fare le squadre
  Widget _buildNonDisponibile(BuildContext context, Responsive r) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: CardBianca(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Non si può inserire il risultato',
              style: stileTesto(r, base: 16, peso: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Servono quattro giocatori: completa prima i partecipanti.',
              style: stileSecondario(r),
            ),
            const SizedBox(height: 12),
            BottonePieno(
              testo: 'Torna indietro',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
