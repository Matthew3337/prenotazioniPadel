import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/gestioneLivelli/gestioneLivelliBloc.dart';
import 'package:thepadel/bloc/gestioneLivelli/gestioneLivelliEvent.dart';
import 'package:thepadel/bloc/gestioneLivelli/gestioneLivelliState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/utenteAdmin.dart';

import 'campoPadel.dart';
import 'stileApp.dart';

class GestioneLivelliPage extends StatelessWidget {
  const GestioneLivelliPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GestioneLivelliBloc>(
      create:
          (_) =>
              sl<GestioneLivelliBloc>()..add(const UtentiRichiesti(cerca: '')),
      child: const _GestioneLivelliView(),
    );
  }
}

// la view e' uno StatefulWidget perche' deve tenere il controller della
// ricerca e il Timer del debounce
class _GestioneLivelliView extends StatefulWidget {
  const _GestioneLivelliView();

  @override
  State<_GestioneLivelliView> createState() => _GestioneLivelliViewState();
}

class _GestioneLivelliViewState extends State<_GestioneLivelliView> {
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
      context.read<GestioneLivelliBloc>().add(
        UtentiRichiesti(cerca: testo.trim()),
      );
    });
  }

  void _ricarica() {
    context.read<GestioneLivelliBloc>().add(
      UtentiRichiesti(cerca: _cercaController.text.trim()),
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
              const TestataIndietro(titolo: 'Gestione livelli'),
              // il campo resta fuori dal builder: cosi' la tastiera non si
              // chiude mentre arriva la lista
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: CampoRicerca(
                  controller: _cercaController,
                  onChanged: _onCercaCambiata,
                ),
              ),
              Expanded(
                child: BlocConsumer<GestioneLivelliBloc, GestioneLivelliState>(
                  listener: (context, state) {
                    if (state is CambioLivelloRiuscito) {
                      mostraSnackBar(context, 'Livello aggiornato');
                    }
                    if (state is CambioLivelloErrore) {
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
    GestioneLivelliState state,
  ) {
    if (state is UtentiErrore) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: CardErrore(
          titolo: 'Non siamo riusciti a caricare gli utenti',
          testo: state.messaggio,
          onRiprova: _ricarica,
        ),
      );
    }
    if (state is UtentiCaricati) {
      return _buildLista(context, r, state.utenti, null);
    }
    // durante il salvataggio la lista resta a schermo e solo la riga
    // dell'utente scelto mostra lo spinner
    if (state is CambioLivelloInCorso) {
      return _buildLista(context, r, state.utenti, state.telefono);
    }
    if (state is CambioLivelloRiuscito) {
      return _buildLista(context, r, state.utenti, null);
    }
    if (state is CambioLivelloErrore) {
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
                    BarraGrigia(larghezza: 120, altezza: 16),
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
    List<UtenteAdmin> utenti,
    String? telefonoInCambio,
  ) {
    final List<Widget> figli = [];
    for (int i = 0; i < utenti.length; i++) {
      if (i > 0) {
        figli.add(const Divider(height: 1, color: Colori.bordo));
      }
      figli.add(_buildRiga(context, r, utenti[i], telefonoInCambio));
    }
    if (utenti.isEmpty) {
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
    UtenteAdmin utente,
    String? telefonoInCambio,
  ) {
    Widget selettore;
    if (telefonoInCambio == utente.telefono) {
      selettore = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colori.bluCampo,
        ),
      );
    } else {
      selettore = _buildSelettore(context, r, utente, telefonoInCambio != null);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Row(
        children: [
          CerchioIniziali(
            testo: inizialiDi(utente.nome, utente.cognome),
            sfondo: Colori.azzurroChiaro,
            colore: Colori.azzurro,
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
                  '${utente.punteggio} punti',
                  style: stileSecondario(r, base: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // larghezza fissa: lo spinner non deve far saltare la riga
          SizedBox(
            width: 76,
            child: Align(alignment: Alignment.centerRight, child: selettore),
          ),
        ],
      ),
    );
  }

  Widget _buildSelettore(
    BuildContext context,
    Responsive r,
    UtenteAdmin utente,
    bool disabilitato,
  ) {
    final List<DropdownMenuItem<double>> voci = [];
    // i livelli vanno da 0 a 5 con passo 0,5
    for (int i = 0; i <= 10; i++) {
      final double livello = i / 2;
      voci.add(
        DropdownMenuItem<double>(
          value: livello,
          child: Text('$livello', style: stileTesto(r)),
        ),
      );
    }

    // un livello fuori dal passo farebbe fallire il DropdownButton, che vuole
    // sempre un valore presente tra le voci: lo mostriamo solo come testo
    final bool valoreValido =
        utente.livello >= 0 &&
        utente.livello <= 5 &&
        (utente.livello * 2) % 1 == 0;

    return Semantics(
      label: 'Livello di ${utente.nome} ${utente.cognome}',
      child: DropdownButton<double>(
        value: valoreValido ? utente.livello : null,
        hint: Text('${utente.livello}', style: stileTesto(r)),
        disabledHint: Text('${utente.livello}', style: stileTesto(r)),
        underline: const SizedBox.shrink(),
        items: voci,
        // un cambio per volta: lo stato ne segue uno solo
        onChanged:
            disabilitato
                ? null
                : (nuovoLivello) {
                  if (nuovoLivello == null || nuovoLivello == utente.livello) {
                    return;
                  }
                  context.read<GestioneLivelliBloc>().add(
                    CambiaLivelloRichiesto(
                      telefono: utente.telefono,
                      livello: nuovoLivello,
                    ),
                  );
                },
      ),
    );
  }
}
