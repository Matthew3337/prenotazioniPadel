import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/partiteGiorno/partiteGiornoBloc.dart';
import 'package:thepadel/bloc/partiteGiorno/partiteGiornoEvent.dart';
import 'package:thepadel/bloc/partiteGiorno/partiteGiornoState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/partitaAdmin.dart';
import 'package:thepadel/domainLayer/enetity/partiteCampoAdmin.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';

import 'dettaglioAdmin.dart';
import 'stileApp.dart';

class PartiteGiornoPage extends StatelessWidget {
  const PartiteGiornoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DateTime adesso = DateTime.now();
    final DateTime oggi = DateTime(adesso.year, adesso.month, adesso.day);

    return BlocProvider<PartiteGiornoBloc>(
      create:
          (_) =>
              sl<PartiteGiornoBloc>()..add(PartiteGiornoRichieste(data: oggi)),
      child: _PartiteGiornoView(dataIniziale: oggi),
    );
  }
}

class _PartiteGiornoView extends StatefulWidget {
  final DateTime dataIniziale;

  const _PartiteGiornoView({required this.dataIniziale});

  @override
  State<_PartiteGiornoView> createState() => _PartiteGiornoViewState();
}

class _PartiteGiornoViewState extends State<_PartiteGiornoView> {
  late DateTime _data;

  @override
  void initState() {
    super.initState();
    _data = widget.dataIniziale;
  }

  void _ricarica() {
    context.read<PartiteGiornoBloc>().add(PartiteGiornoRichieste(data: _data));
  }

  void _cambiaData(DateTime nuovaData) {
    setState(() {
      _data = nuovaData;
    });
    _ricarica();
  }

  // uso il costruttore e non add(Duration): col cambio dell'ora legale un
  // giorno non e' sempre di 24 ore
  void _spostaGiorno(int giorni) {
    _cambiaData(DateTime(_data.year, _data.month, _data.day + giorni));
  }

  Future<void> _scegliData() async {
    // i limiti partono dalla data mostrata: con le frecce si puo' arrivare a
    // qualsiasi giorno, e il picker si blocca se la data iniziale e' fuori limite
    final DateTime? scelta = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(_data.year - 5),
      lastDate: DateTime(_data.year + 5, 12, 31),
      helpText: 'Scegli il giorno',
      cancelText: 'Chiudi',
      confirmText: 'Conferma',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colori.bluCampo,
              onPrimary: Colors.white,
              onSurface: Colori.testo,
            ),
          ),
          child: child!,
        );
      },
    );

    if (scelta != null && mounted) {
      _cambiaData(scelta);
    }
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
              const TestataIndietro(titolo: 'Partite del giorno'),
              Expanded(
                child: BlocBuilder<PartiteGiornoBloc, PartiteGiornoState>(
                  builder: (context, state) {
                    // il bloc non dice a che giorno si riferisce la risposta:
                    // cambiando data con una richiesta ancora in giro si
                    // rischierebbero le partite del giorno sbagliato
                    final bool isLoading =
                        state is! PartiteGiornoCaricate &&
                        state is! PartiteGiornoErrore;

                    List<Widget> elementi;
                    if (state is PartiteGiornoCaricate) {
                      elementi = _buildCampi(r, state.campi);
                    } else if (state is PartiteGiornoErrore) {
                      elementi = [
                        CardErrore(
                          titolo: 'Non siamo riusciti a caricare le partite',
                          testo: state.messaggio,
                          onRiprova: _ricarica,
                        ),
                      ];
                    } else {
                      elementi = _buildScheletro();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: _buildSelettoreData(r, isLoading),
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            children: elementi,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== SELETTORE DATA =====

  Widget _buildSelettoreData(Responsive r, bool isLoading) {
    return CardBianca(
      child: Row(
        children: [
          IconButton(
            tooltip: 'Giorno precedente',
            icon: const Icon(Icons.chevron_left, color: Colori.testo),
            onPressed:
                isLoading
                    ? null
                    : () {
                      _spostaGiorno(-1);
                    },
          ),
          Expanded(
            child: InkWell(
              onTap: isLoading ? null : _scegliData,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Center(
                  child: Text(
                    conMaiuscola(dataEstesa(_data)),
                    textAlign: TextAlign.center,
                    style: stileTesto(r, base: 16, peso: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Giorno successivo',
            icon: const Icon(Icons.chevron_right, color: Colori.testo),
            onPressed:
                isLoading
                    ? null
                    : () {
                      _spostaGiorno(1);
                    },
          ),
        ],
      ),
    );
  }

  // ===== CARICAMENTO =====

  List<Widget> _buildScheletro() {
    final List<Widget> elementi = [];
    for (int i = 0; i < 2; i++) {
      elementi.add(
        const Align(
          alignment: Alignment.centerLeft,
          child: BarraGrigia(larghezza: 150, altezza: 22),
        ),
      );
      elementi.add(const SizedBox(height: 8));
      elementi.add(const BarraGrigia(altezza: 110, raggio: 20));
      elementi.add(const SizedBox(height: 16));
    }
    return elementi;
  }

  // ===== CAMPI E PARTITE =====

  List<Widget> _buildCampi(Responsive r, List<PartiteCampoAdmin> campi) {
    if (campi.isEmpty) {
      return [
        CardBianca(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text('Nessun campo disponibile', style: stileSecondario(r)),
        ),
      ];
    }

    final List<Widget> elementi = [];
    for (final campo in campi) {
      elementi.add(Text(campo.nomeCampo, style: stileNumero(r, 18)));
      elementi.add(const SizedBox(height: 8));
      if (campo.partite.isEmpty) {
        elementi.add(
          CardBianca(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text('Nessuna partita', style: stileSecondario(r)),
          ),
        );
        elementi.add(const SizedBox(height: 8));
      }
      for (final partita in campo.partite) {
        elementi.add(_buildPartita(r, partita));
        elementi.add(const SizedBox(height: 8));
      }
      elementi.add(const SizedBox(height: 8));
    }
    return elementi;
  }

  Widget _buildPartita(Responsive r, PartitaAdmin partita) {
    final String giocatori =
        partita.giocatori.isEmpty
            ? 'Nessun giocatore'
            : partita.giocatori.join(', ');
    final String risultato = _testoRisultato(partita.risultato);

    return CardBianca(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () {
        _apriDettaglio(partita.id);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formattaOra(partita.oraInizio)} - ${formattaOra(partita.oraFine)}',
                  style: stileTesto(r, base: 16, peso: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              PillolaStato(stato: partita.stato),
            ],
          ),
          const SizedBox(height: 4),
          Text(giocatori, style: stileSecondario(r)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  testoPostiLiberi(partita.postiLiberi),
                  style: stileSecondario(r, base: 14),
                ),
              ),
              if (risultato.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(risultato, style: stileNumero(r, 15)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // es. "6-4 3-6"
  String _testoRisultato(List<SetPartita>? risultato) {
    if (risultato == null) {
      return '';
    }
    final List<String> set = [];
    for (final singolo in risultato) {
      set.add('${singolo.squadra1}-${singolo.squadra2}');
    }
    return set.join(' ');
  }

  Future<void> _apriDettaglio(int idPartita) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DettaglioAdminPage(idPartita: idPartita),
      ),
    );

    if (mounted) {
      _ricarica();
    }
  }
}
