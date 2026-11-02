import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:thepadel/bloc/classifica/classificaBloc.dart';
import 'package:thepadel/bloc/classifica/classificaEvent.dart';
import 'package:thepadel/bloc/classifica/classificaState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/voceClassifica.dart';

class ClassificaPage extends StatelessWidget {
  const ClassificaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ClassificaBloc>(
      create: (_) => sl<ClassificaBloc>()..add(const ClassificaRichiesta()),
      child: const _ClassificaView(),
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

class _ClassificaView extends StatelessWidget {
  const _ClassificaView();

  static const Color backgroundColor = Color(0xFFF7F8FC);
  static const Color primaryColor = Color(0xFF4564B1);
  static const Color darkText = Color(0xFF252B3A);
  static const Color greyText = Color(0xFF7D8597);
  static const Color borderColor = Color(0xFFE0E3EA);

  // lo stesso azzurro chiaro del badge "Creata" nel dettaglio e nello storico
  static const Color primarioChiaro = Color(0xFFE7F1FC);

  // stesse tinte del badge della posizione nella card della home
  static const Color podioSfondo = Color(0xFFFFF0D9);
  static const Color podioTesto = Color(0xFF92530B);

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
                  child: BlocBuilder<ClassificaBloc, ClassificaState>(
                    builder: (context, state) {
                      if (state is ClassificaErrore) {
                        return _buildErrore(context, r, state.messaggio);
                      }

                      if (state is ClassificaCaricata) {
                        return _buildLista(context, r, state.voci);
                      }

                      // ClassificaInitial e ClassificaLoading
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
            'Classifica',
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
                context.read<ClassificaBloc>().add(const ClassificaRichiesta());
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
  // LISTA GIOCATORI
  // =====================================================================

  Widget _buildLista(
    BuildContext context,
    _Responsive r,
    List<VoceClassifica> voci,
  ) {
    final List<Widget> elementi = [];

    if (voci.isEmpty) {
      elementi.add(_buildVuota(r));
    }

    // l'ordine e' quello deciso dal server, qui non si riordina niente
    for (final voce in voci) {
      elementi.add(_buildRiga(r, voce));
      elementi.add(const SizedBox(height: 10));
    }

    // la lista deve poter scorrere anche quando e' corta o vuota,
    // altrimenti il pull-to-refresh non parte
    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () async {
        context.read<ClassificaBloc>().add(const ClassificaRichiesta());
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
      sfondo: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            _iconBox(r, Icons.bar_chart_outlined),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Nessun giocatore in classifica',
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
  // RIGA GIOCATORE
  // =====================================================================

  Widget _buildRiga(_Responsive r, VoceClassifica voce) {
    Color sfondo = Colors.white;
    FontWeight pesoTesto = FontWeight.w500;

    if (voce.utenteCorrente) {
      sfondo = primarioChiaro;
      pesoTesto = FontWeight.w700;
    }

    return _buildCard(
      r: r,
      sfondo: sfondo,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 18, 12),
        child: Row(
          children: [
            _badgePosizione(r, voce.posizione, pesoTesto),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '${voce.nome} ${voce.cognome}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: r.font(16),
                  fontWeight: pesoTesto,
                  color: darkText,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${voce.punteggio} pt',
              style: TextStyle(
                fontSize: r.font(15),
                fontWeight: pesoTesto,
                color: darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // a pari punti la posizione si ripete (1, 2, 2, 4), quindi l'accento
  // dipende dal numero e non dall'indice della riga: con un pari merito
  // le righe colorate possono essere piu' di tre
  Widget _badgePosizione(_Responsive r, int posizione, FontWeight peso) {
    final size = (r.width * 0.11).clamp(40.0, 48.0);

    Color sfondo = borderColor;
    Color colore = darkText;

    if (posizione <= 3) {
      sfondo = podioSfondo;
      colore = podioTesto;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: sfondo, shape: BoxShape.circle),
      child: Center(
        child: Text(
          '$posizione',
          style: TextStyle(
            fontSize: r.font(16),
            fontWeight: peso,
            color: colore,
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
        color: primarioChiaro,
        borderRadius: BorderRadius.circular(size * 0.26),
      ),
      child: Icon(icon, color: const Color(0xFF2168B4), size: size * 0.5),
    );
  }

  Widget _buildCard({
    required _Responsive r,
    required Color sfondo,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: sfondo,
        borderRadius: BorderRadius.circular(r.cardBorderRadius),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: child,
    );
  }
}
