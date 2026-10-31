import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:thepadel/bloc/creaPartita/creaPartitaBloc.dart';
import 'package:thepadel/bloc/creaPartita/creaPartitaEvent.dart';
import 'package:thepadel/bloc/creaPartita/creaPartitaState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';

class CreaPartitaPage extends StatelessWidget {
  final SlotOrario slot;
  final DateTime data;

  const CreaPartitaPage({super.key, required this.slot, required this.data});

  @override
  Widget build(BuildContext context) {
    // nessun evento iniziale: la richiesta parte solo quando l'utente
    // tocca "Prenota"
    return BlocProvider<CreaPartitaBloc>(
      create: (_) => sl<CreaPartitaBloc>(),
      child: _CreaPartitaView(slot: slot, data: data),
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
        textScale =
            (MediaQuery.sizeOf(context).width / 390).clamp(0.8, 1.1);

  double font(double base) => base * textScale;

  double get horizontalPadding => (width * 0.06).clamp(20.0, 48.0);

  double get cardBorderRadius => isTablet ? 32 : 26;

  double get maxContentWidth => isTablet ? 640 : double.infinity;
}

class _CreaPartitaView extends StatefulWidget {
  final SlotOrario slot;
  final DateTime data;

  const _CreaPartitaView({required this.slot, required this.data});

  @override
  State<_CreaPartitaView> createState() => _CreaPartitaViewState();
}

class _CreaPartitaViewState extends State<_CreaPartitaView> {
  static const Color backgroundColor = Color(0xFFF7F8FC);
  static const Color primaryColor = Color(0xFF4564B1);
  static const Color darkText = Color(0xFF252B3A);
  static const Color greyText = Color(0xFF7D8597);
  static const Color borderColor = Color(0xFFE0E3EA);

  // stringa vuota finche' l'utente non sceglie: e' il BLoC a segnalare
  // l'errore se si preme "Prenota" senza aver scelto
  String _tipoScelto = '';

  @override
  Widget build(BuildContext context) {
    final r = _Responsive(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: BlocConsumer<CreaPartitaBloc, CreaPartitaState>(
          listener: (context, state) {
            if (state is CreaPartitaSuccess) {
              _mostraSnackBar(context, r, 'Partita creata');
              // restituiamo l'id alla home: e' lei ad aprire il dettaglio,
              // cosi' al ritorno dal dettaglio puo' ricaricarsi di nuovo
              Navigator.pop(context, state.prenotazione.id);
            }
            if (state is CreaPartitaErrore) {
              _mostraSnackBar(context, r, state.messaggio);
            }
          },
          builder: (context, state) {
            final isLoading = state is CreaPartitaLoading;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          r.horizontalPadding,
                          16,
                          r.horizontalPadding,
                          16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context, r),
                            const SizedBox(height: 22),
                            _buildRiepilogo(r),
                            const SizedBox(height: 18),
                            _buildTipoPartita(r, isLoading),
                          ],
                        ),
                      ),
                    ),
                    _buildBottonePrenota(context, r, isLoading),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
            'Riepilogo partita',
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
  // RIEPILOGO SLOT
  // =====================================================================

  Widget _buildRiepilogo(_Responsive r) {
    final String giorno = _giornoSettimana(widget.data);
    final String data = _formatData(widget.data);
    final String oraInizio = _formatOra(widget.slot.oraInizio);
    final String oraFine = _formatOra(widget.slot.oraFine);

    return _buildCard(
      r: r,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Slot scelto',
              style: TextStyle(
                fontSize: r.font(17),
                fontWeight: FontWeight.w500,
                color: greyText,
              ),
            ),
            const SizedBox(height: 14),
            _rigaRiepilogo(
              r,
              icona: Icons.sports_tennis,
              etichetta: 'Campo',
              valore: widget.slot.nomeCampo,
            ),
            const SizedBox(height: 14),
            _rigaRiepilogo(
              r,
              icona: Icons.calendar_month_outlined,
              etichetta: 'Data',
              valore: '$giorno $data',
            ),
            const SizedBox(height: 14),
            _rigaRiepilogo(
              r,
              icona: Icons.access_time,
              etichetta: 'Orario',
              valore: '$oraInizio - $oraFine',
            ),
          ],
        ),
      ),
    );
  }

  Widget _rigaRiepilogo(
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

  // =====================================================================
  // TIPO PARTITA
  // =====================================================================

  Widget _buildTipoPartita(_Responsive r, bool isLoading) {
    return _buildCard(
      r: r,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tipo di partita',
              style: TextStyle(
                fontSize: r.font(17),
                fontWeight: FontWeight.w500,
                color: greyText,
              ),
            ),
            const SizedBox(height: 14),
            _opzioneTipo(
              r,
              valore: 'PUBBLICA',
              titolo: 'Pubblica',
              descrizione:
                  'Visibile in bacheca agli utenti di livello simile al tuo',
              icona: Icons.public,
              isLoading: isLoading,
            ),
            const SizedBox(height: 12),
            _opzioneTipo(
              r,
              valore: 'PRIVATA',
              titolo: 'Privata',
              descrizione: 'Visibile solo agli utenti che inviti',
              icona: Icons.lock_outline,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _opzioneTipo(
    _Responsive r, {
    required String valore,
    required String titolo,
    required String descrizione,
    required IconData icona,
    required bool isLoading,
  }) {
    final bool selezionata = _tipoScelto == valore;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      // durante l'invio la scelta resta bloccata
      onTap: isLoading
          ? null
          : () {
              setState(() {
                _tipoScelto = valore;
              });
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selezionata ? const Color(0xFFE7F1FC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selezionata ? primaryColor : borderColor,
            width: selezionata ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icona,
              color: selezionata ? primaryColor : greyText,
              size: r.font(26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titolo,
                    style: TextStyle(
                      fontSize: r.font(16),
                      fontWeight: FontWeight.w600,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    descrizione,
                    style: TextStyle(
                      fontSize: r.font(13),
                      color: greyText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selezionata
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selezionata ? primaryColor : greyText,
              size: r.font(22),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // BOTTONE PRENOTA
  // =====================================================================

  Widget _buildBottonePrenota(
    BuildContext context,
    _Responsive r,
    bool isLoading,
  ) {
    final double altezza = (r.height * 0.065).clamp(48.0, 60.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        r.horizontalPadding,
        8,
        r.horizontalPadding,
        16,
      ),
      child: SizedBox(
        width: double.infinity,
        height: altezza,
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : () {
                  context.read<CreaPartitaBloc>().add(
                        CreaPartitaRichiesta(
                          slot: widget.slot,
                          data: widget.data,
                          tipo: _tipoScelto,
                        ),
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
          child: isLoading
              ? SizedBox(
                  width: r.font(22),
                  height: r.font(22),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Prenota',
                  style: TextStyle(
                    fontSize: r.font(16),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
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

  Widget _buildCard({
    required _Responsive r,
    required Widget child,
  }) {
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

  // il server puo' mandare l'ora con i secondi ("18:30:00"):
  // teniamo solo ore e minuti
  String _formatOra(String ora) {
    if (ora.length > 5) {
      return ora.substring(0, 5);
    }
    return ora;
  }
}
