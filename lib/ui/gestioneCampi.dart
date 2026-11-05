import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/gestioneCampi/gestioneCampiBloc.dart';
import 'package:thepadel/bloc/gestioneCampi/gestioneCampiEvent.dart';
import 'package:thepadel/bloc/gestioneCampi/gestioneCampiState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/campo.dart';

import 'formCampo.dart';
import 'stileApp.dart';

class GestioneCampiPage extends StatelessWidget {
  const GestioneCampiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GestioneCampiBloc>(
      create: (_) => sl<GestioneCampiBloc>()..add(const CampiRichiesti()),
      child: const _GestioneCampiView(),
    );
  }
}

class _GestioneCampiView extends StatelessWidget {
  const _GestioneCampiView();

  // il form riceve questo stesso bloc: cosi' al ritorno l'elenco e' gia'
  // aggiornato senza richiederlo al server
  void _apriForm(BuildContext context, Campo? campo) {
    final GestioneCampiBloc bloc = context.read<GestioneCampiBloc>();
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => FormCampoPage(campo: campo, bloc: bloc),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TestataIndietro(titolo: 'Gestione campi'),
              Expanded(
                child: BlocConsumer<GestioneCampiBloc, GestioneCampiState>(
                  listener: (context, state) {
                    // Il bloc e' condiviso con il form: finche' e' aperto i
                    // messaggi li mostra lui. Qui arrivano solo se si e' tornati
                    // indietro mentre l'operazione era ancora in corso.
                    final bool inPrimoPiano =
                        ModalRoute.of(context)?.isCurrent ?? true;
                    if (!inPrimoPiano) {
                      return;
                    }
                    if (state is CampoSalvato) {
                      mostraSnackBar(context, 'Campo salvato');
                    }
                    if (state is CampoEliminato) {
                      mostraSnackBar(context, 'Campo eliminato');
                    }
                    if (state is CampoOperazioneErrore) {
                      mostraSnackBar(context, state.messaggio);
                    }
                  },
                  builder: (context, state) {
                    return _buildCorpo(context, r, state);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCorpo(
    BuildContext context,
    Responsive r,
    GestioneCampiState state,
  ) {
    if (state is CampiErrore) {
      return _buildErrore(context, state.messaggio);
    }
    if (state is CampiCaricati) {
      return _buildLista(context, r, state.campi);
    }
    if (state is CampoInCorso) {
      return _buildLista(context, r, state.campi);
    }
    if (state is CampoSalvato) {
      return _buildLista(context, r, state.campi);
    }
    if (state is CampoEliminato) {
      return _buildLista(context, r, state.campi);
    }
    if (state is CampoOperazioneErrore) {
      return _buildLista(context, r, state.campi);
    }
    return _buildScheletro();
  }

  // ===== CARICAMENTO =====

  Widget _buildScheletro() {
    final List<Widget> righe = [];
    for (int i = 0; i < 3; i++) {
      if (i > 0) {
        righe.add(const SizedBox(height: 12));
      }
      righe.add(const BarraGrigia(altezza: 92, raggio: 20));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(children: righe),
    );
  }

  // ===== ERRORE =====

  Widget _buildErrore(BuildContext context, String messaggio) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: CardErrore(
        titolo: 'Non siamo riusciti a caricare i campi',
        testo: messaggio,
        onRiprova: () {
          context.read<GestioneCampiBloc>().add(const CampiRichiesti());
        },
      ),
    );
  }

  // ===== ELENCO =====

  Widget _buildLista(BuildContext context, Responsive r, List<Campo> campi) {
    final List<Widget> figli = [];
    for (int i = 0; i < campi.length; i++) {
      if (i > 0) {
        figli.add(const SizedBox(height: 12));
      }
      figli.add(_buildCampo(context, r, campi[i]));
    }
    if (campi.isEmpty) {
      figli.add(
        CardBianca(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Non ci sono ancora campi. Aggiungine uno con "Nuovo campo".',
            style: stileSecondario(r),
          ),
        ),
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
              children: figli,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: BottonePieno(
            testo: 'Nuovo campo',
            altezza: 52,
            baseFont: 16,
            onPressed: () {
              _apriForm(context, null);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCampo(BuildContext context, Responsive r, Campo campo) {
    return CardBianca(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () {
        _apriForm(context, campo);
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(campo.nome, style: stileNumero(r, 18)),
                const SizedBox(height: 2),
                Text(
                  '${formattaOra(campo.oraApertura)} - ${formattaOra(campo.oraChiusura)}',
                  style: stileSecondario(r),
                ),
                const SizedBox(height: 6),
                Pillola(
                  testo: campo.alCoperto ? 'Al coperto' : "All'aperto",
                  sfondo: campo.alCoperto ? Colori.azzurroChiaro : Colori.bordo,
                  colore: campo.alCoperto ? Colori.azzurro : Colori.testo,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colori.grigio),
        ],
      ),
    );
  }
}
