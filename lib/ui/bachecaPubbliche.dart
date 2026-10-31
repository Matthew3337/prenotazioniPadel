import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:thepadel/bloc/bachecaPubbliche/bachecaPubblicheBloc.dart';
import 'package:thepadel/bloc/bachecaPubbliche/bachecaPubblicheEvent.dart';
import 'package:thepadel/bloc/bachecaPubbliche/bachecaPubblicheState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/partitaPubblica.dart';

import 'dettaglioPartita.dart';

class BachecaPubblichePage extends StatelessWidget {
  const BachecaPubblichePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BachecaPubblicheBloc>(
      create:
          (_) =>
              sl<BachecaPubblicheBloc>()..add(const BachecaPubblicheRichiesta()),
      child: const _BachecaPubblicheView(),
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

class _BachecaPubblicheView extends StatelessWidget {
  const _BachecaPubblicheView();

  static const Color backgroundColor = Color(0xFFF7F8FC);
  static const Color primaryColor = Color(0xFF4564B1);
  static const Color darkText = Color(0xFF252B3A);
  static const Color greyText = Color(0xFF7D8597);
  static const Color borderColor = Color(0xFFE0E3EA);

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
                  child: BlocConsumer<
                    BachecaPubblicheBloc,
                    BachecaPubblicheState
                  >(
                    listener: (context, state) {
                      if (state is IngressoRiuscito) {
                        _apriDettaglio(context, state.dettaglio.id);
                      }
                      // dopo l'errore il BLoC ricarica la bacheca da solo,
                      // qui basta avvisare l'utente
                      if (state is IngressoErrore) {
                        _mostraSnackBar(context, r, state.messaggio);
                      }
                    },
                    builder: (context, state) {
                      if (state is BachecaPubblicheErrore) {
                        return _buildErrore(context, r, state.messaggio);
                      }

                      if (state is BachecaPubblicheCaricata) {
                        return _buildLista(context, r, state.partite, null);
                      }

                      // durante l'ingresso la lista resta a schermo e solo la
                      // card scelta mostra lo spinner
                      if (state is IngressoInCorso) {
                        return _buildLista(
                          context,
                          r,
                          state.partite,
                          state.idPartita,
                        );
                      }

                      if (state is IngressoRiuscito) {
                        return _buildLista(context, r, state.partite, null);
                      }

                      if (state is IngressoErrore) {
                        return _buildLista(context, r, state.partite, null);
                      }

                      // BachecaPubblicheInitial e BachecaPubblicheLoading
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

    // al ritorno dal dettaglio la bacheca puo' essere cambiata (ad esempio
    // la partita in cui l'utente e' entrato non deve piu' comparire)
    if (context.mounted) {
      context.read<BachecaPubblicheBloc>().add(
        const BachecaPubblicheRichiesta(),
      );
    }
  }

  void _mostraSnackBar(BuildContext context, _Responsive r, String testo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(testo),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(
          horizontal: r.width * 0.05,
          vertical: r.height * 0.02,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
            'Partite pubbliche',
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
                context.read<BachecaPubblicheBloc>().add(
                  const BachecaPubblicheRichiesta(),
                );
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

  // idInIngresso e' l'id della partita in cui l'utente sta entrando,
  // null quando non c'e' nessun ingresso in corso
  Widget _buildLista(
    BuildContext context,
    _Responsive r,
    List<PartitaPubblica> partite,
    int? idInIngresso,
  ) {
    final List<Widget> elementi = [];

    if (partite.isEmpty) {
      elementi.add(_buildVuota(r));
    }

    for (final partita in partite) {
      final bool inIngresso = partita.id == idInIngresso;
      elementi.add(_buildPartitaCard(context, r, partita, inIngresso));
      elementi.add(const SizedBox(height: 14));
    }

    // la lista deve poter scorrere anche quando e' corta o vuota,
    // altrimenti il pull-to-refresh non parte
    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () async {
        context.read<BachecaPubblicheBloc>().add(
          const BachecaPubblicheRichiesta(),
        );
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
            _iconBox(r, Icons.public),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Nessuna partita pubblica disponibile al momento',
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
    PartitaPubblica partita,
    bool inIngresso,
  ) {
    final String giorno = _giornoSettimana(partita.dataPartita);
    final String data = _formatData(partita.dataPartita);
    final String oraInizio = _formatTime(partita.oraInizio);
    final String oraFine = _formatTime(partita.oraFine);
    final String creatore =
        '${partita.nomeCreatore} ${partita.cognomeCreatore}'.trim();

    return _buildCard(
      r: r,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
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
                _badgePosti(r, partita.postiLiberi),
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
            const SizedBox(height: 14),
            _rigaInfo(
              r,
              icona: Icons.person_outline,
              etichetta: 'Creata da',
              valore:
                  '$creatore · Livello ${partita.livelloCreatore.toStringAsFixed(1)}',
            ),
            const SizedBox(height: 16),
            _bottoneEntra(context, r, partita.id, inIngresso),
          ],
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

  // stesse tinte verdi usate in home per gli slot disponibili
  Widget _badgePosti(_Responsive r, int postiLiberi) {
    String testo = '$postiLiberi posti liberi';
    if (postiLiberi == 1) {
      testo = '1 posto libero';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F4EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        testo,
        style: TextStyle(
          color: const Color(0xFF075E50),
          fontSize: r.font(13),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _bottoneEntra(
    BuildContext context,
    _Responsive r,
    int idPartita,
    bool inIngresso,
  ) {
    final double altezza = (r.height * 0.06).clamp(44.0, 56.0);

    return SizedBox(
      width: double.infinity,
      height: altezza,
      child: ElevatedButton(
        onPressed:
            inIngresso
                ? null
                : () {
                  context.read<BachecaPubblicheBloc>().add(
                    EntraInPartitaRichiesto(idPartita: idPartita),
                  );
                },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          disabledBackgroundColor: const Color(0xFF9AA8C8),
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: primaryColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child:
            inIngresso
                ? SizedBox(
                  width: r.font(22),
                  height: r.font(22),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                : Text(
                  'Entra',
                  style: TextStyle(
                    fontSize: r.font(16),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
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
