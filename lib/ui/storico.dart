import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:thepadel/bloc/storico/storicoBloc.dart';
import 'package:thepadel/bloc/storico/storicoEvent.dart';
import 'package:thepadel/bloc/storico/storicoState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/partitaStorico.dart';
import 'package:thepadel/domainLayer/enetity/risultatoPartita.dart';

import 'dettaglioPartita.dart';

class StoricoPage extends StatelessWidget {
  const StoricoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StoricoBloc>(
      create: (_) => sl<StoricoBloc>()..add(const StoricoRichiesto()),
      child: const _StoricoView(),
    );
  }
}

/// Helper responsive: stesso sistema usato in home, font scalati sulla
/// larghezza di un iPhone standard (~390px) e padding clampati.
class _Responsive {
  final BuildContext context;
  final double width;
  final double height;
  final bool isTablet;
  final double textScale;

  _Responsive(this.context)
    : width = MediaQuery.sizeOf(context).width,
      height = MediaQuery.sizeOf(context).height,
      isTablet = MediaQuery.sizeOf(context).width >= 600,
      textScale = (MediaQuery.sizeOf(context).width / 390).clamp(0.8, 1.1);

  double font(double base) => base * textScale;

  double get horizontalPadding => (width * 0.06).clamp(20.0, 48.0);

  double get cardBorderRadius => isTablet ? 32 : 26;

  double get maxContentWidth => isTablet ? 640 : double.infinity;
}

class _StoricoView extends StatelessWidget {
  const _StoricoView();

  static const Color backgroundColor = Color(0xFFF7F8FC);
  static const Color primaryColor = Color(0xFF4564B1);
  static const Color darkText = Color(0xFF252B3A);
  static const Color greyText = Color(0xFF7D8597);
  static const Color borderColor = Color(0xFFE0E3EA);

  // stesse tinte verde e rossa del badge di stato nel dettaglio
  static const Color verde = Color(0xFF075E50);
  static const Color rosso = Color(0xFFA33A3A);

  @override
  Widget build(BuildContext context) {
    final r = _Responsive(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: r.maxContentWidth),
            child: Column(
              children: [
                // l'header resta fuori dal builder, cosi' la freccia
                // indietro c'e' anche durante il caricamento e in errore
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    r.horizontalPadding,
                    16,
                    r.horizontalPadding,
                    0,
                  ),
                  child: _buildHeader(context, r),
                ),
                Expanded(
                  child: BlocBuilder<StoricoBloc, StoricoState>(
                    builder: (context, state) {
                      if (state is StoricoErrore) {
                        return _buildErrore(context, r, state.messaggio);
                      }

                      if (state is StoricoCaricato) {
                        return _buildLista(context, r, state.partite);
                      }

                      // StoricoInitial e StoricoLoading
                      return const Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _apriDettaglio(BuildContext context, int idPartita) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DettaglioPartitaPage(idPartita: idPartita),
      ),
    );

    // dal dettaglio l'utente puo' uscire dalla partita o eliminarla,
    // quindi al ritorno lo storico va ricaricato
    if (context.mounted) {
      context.read<StoricoBloc>().add(const StoricoRichiesto());
    }
  }

  // =====================================================================
  // HEADER
  // =====================================================================

  Widget _buildHeader(BuildContext context, _Responsive r) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: darkText, size: r.font(24)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Storico partite',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: r.font(24),
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // ERRORE
  // =====================================================================

  Widget _buildErrore(BuildContext context, _Responsive r, String messaggio) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: r.font(32),
            ),
            const SizedBox(height: 10),
            Text(
              messaggio,
              textAlign: TextAlign.center,
              style: TextStyle(color: greyText, fontSize: r.font(15)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                context.read<StoricoBloc>().add(const StoricoRichiesto());
              },
              child: Text(
                'Riprova',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: r.font(15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // LISTA PARTITE
  // =====================================================================

  Widget _buildLista(
    BuildContext context,
    _Responsive r,
    List<PartitaStorico> partite,
  ) {
    final List<Widget> elementi = [];

    if (partite.isEmpty) {
      elementi.add(_buildVuota(r));
    }

    for (final partita in partite) {
      elementi.add(_buildPartitaCard(context, r, partita));
      elementi.add(const SizedBox(height: 14));
    }

    // la lista deve poter scorrere anche quando e' corta o vuota,
    // altrimenti il pull-to-refresh non parte
    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () async {
        context.read<StoricoBloc>().add(const StoricoRichiesto());
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          r.horizontalPadding,
          22,
          r.horizontalPadding,
          16,
        ),
        children: elementi,
      ),
    );
  }

  Widget _buildVuota(_Responsive r) {
    return _buildCard(
      r: r,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            _iconBox(r, Icons.history),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Non hai ancora partite nello storico',
                style: TextStyle(
                  fontSize: r.font(16),
                  fontWeight: FontWeight.w500,
                  color: darkText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // CARD PARTITA
  // =====================================================================

  Widget _buildPartitaCard(
    BuildContext context,
    _Responsive r,
    PartitaStorico partita,
  ) {
    final String giorno = _giornoSettimana(partita.dataPartita);
    final String data = _formatData(partita.dataPartita);
    final String oraInizio = _formatTime(partita.oraInizio);
    final String oraFine = _formatTime(partita.oraFine);

    final List<Widget> righe = [
      Row(
        children: [
          Expanded(
            child: Text(
              partita.nomeCampo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: r.font(18),
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _badgeStato(r, partita.stato),
        ],
      ),
      const SizedBox(height: 14),
      _rigaInfo(
        r,
        icona: Icons.calendar_month_outlined,
        etichetta: 'Data',
        valore: '$giorno $data',
      ),
      const SizedBox(height: 14),
      _rigaInfo(
        r,
        icona: Icons.access_time,
        etichetta: 'Orario',
        valore: '$oraInizio - $oraFine',
      ),
    ];

    // senza set non c'e' niente da mostrare, anche se il risultato esiste
    final RisultatoPartita? risultato = partita.risultato;
    if (risultato != null && risultato.set.isNotEmpty) {
      righe.add(const SizedBox(height: 14));
      righe.add(_rigaRisultato(r, risultato));
    }

    return InkWell(
      borderRadius: BorderRadius.circular(r.cardBorderRadius),
      onTap: () {
        _apriDettaglio(context, partita.id);
      },
      child: _buildCard(
        r: r,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: righe,
          ),
        ),
      ),
    );
  }

  Widget _rigaInfo(
    _Responsive r, {
    required IconData icona,
    required String etichetta,
    required String valore,
  }) {
    return Row(
      children: [
        _iconBox(r, icona),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etichetta,
                style: TextStyle(
                  fontSize: r.font(13),
                  fontWeight: FontWeight.w500,
                  color: greyText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valore,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: r.font(16),
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // il server da' i set come squadra1-squadra2: se l'utente e' nella
  // squadra 2 li giriamo, cosi' il primo numero sono sempre i suoi game
  Widget _rigaRisultato(_Responsive r, RisultatoPartita risultato) {
    String testo = '';
    for (final set in risultato.set) {
      String punteggio = '${set.squadra1}-${set.squadra2}';
      if (risultato.squadraUtente == 2) {
        punteggio = '${set.squadra2}-${set.squadra1}';
      }

      if (testo.isEmpty) {
        testo = punteggio;
      } else {
        testo = '$testo $punteggio';
      }
    }

    Color colore = darkText;
    if (risultato.esito == 'VINTA') {
      testo = '$testo · Vinta';
      colore = verde;
    }
    if (risultato.esito == 'PERSA') {
      testo = '$testo · Persa';
      colore = rosso;
    }

    final int? punti = risultato.puntiAssegnati;
    if (punti != null) {
      // i punti negativi hanno gia' il meno davanti
      if (punti > 0) {
        testo = '$testo · +$punti punti';
      } else {
        testo = '$testo · $punti punti';
      }
    }

    return Row(
      children: [
        _iconBox(r, Icons.emoji_events_outlined),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Risultato',
                style: TextStyle(
                  fontSize: r.font(13),
                  fontWeight: FontWeight.w500,
                  color: greyText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                testo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: r.font(16),
                  fontWeight: FontWeight.w600,
                  color: colore,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // stessi testi e colori del badge nel dettaglio partita; le annullate
  // il server non le manda nello storico
  Widget _badgeStato(_Responsive r, String stato) {
    String testo = stato;
    Color sfondo = borderColor;
    Color colore = greyText;

    if (stato == 'creata') {
      testo = 'Creata';
      sfondo = const Color(0xFFE7F1FC);
      colore = primaryColor;
    }
    if (stato == 'confermata') {
      testo = 'Confermata';
      sfondo = const Color(0xFFE0F4EE);
      colore = verde;
    }
    if (stato == 'giocata') {
      testo = 'Giocata';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: sfondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        testo,
        style: TextStyle(
          color: colore,
          fontSize: r.font(13),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // =====================================================================
  // CARD GENERICA
  // =====================================================================

  Widget _iconBox(_Responsive r, IconData icon) {
    final size = (r.width * 0.13).clamp(44.0, 56.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE7F1FC),
        borderRadius: BorderRadius.circular(size * 0.26),
      ),
      child: Icon(icon, color: const Color(0xFF2168B4), size: size * 0.5),
    );
  }

  Widget _buildCard({required _Responsive r, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.cardBorderRadius),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: child,
    );
  }

  // =====================================================================
  // DATE / TIME
  // =====================================================================

  String _giornoSettimana(DateTime date) {
    const giorni = [
      'lunedì',
      'martedì',
      'mercoledì',
      'giovedì',
      'venerdì',
      'sabato',
      'domenica',
    ];
    return giorni[date.weekday - 1];
  }

  String _formatData(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}
