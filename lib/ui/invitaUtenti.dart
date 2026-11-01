import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:thepadel/bloc/invitaUtenti/invitaUtentiBloc.dart';
import 'package:thepadel/bloc/invitaUtenti/invitaUtentiEvent.dart';
import 'package:thepadel/bloc/invitaUtenti/invitaUtentiState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/utenteInvitabile.dart';

class InvitaUtentiPage extends StatelessWidget {
  final int idPartita;

  const InvitaUtentiPage({super.key, required this.idPartita});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InvitaUtentiBloc>(
      create:
          (_) =>
              sl<InvitaUtentiBloc>()
                ..add(InvitabiliRichiesti(idPartita: idPartita, cerca: "")),
      child: _InvitaUtentiView(idPartita: idPartita),
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

// la view e' uno StatefulWidget perche' deve tenere il controller della
// ricerca e il Timer del debounce
class _InvitaUtentiView extends StatefulWidget {
  final int idPartita;

  const _InvitaUtentiView({required this.idPartita});

  @override
  State<_InvitaUtentiView> createState() => _InvitaUtentiViewState();
}

class _InvitaUtentiViewState extends State<_InvitaUtentiView> {
  static const Color backgroundColor = Color(0xFFF7F8FC);
  static const Color primaryColor = Color(0xFF4564B1);
  static const Color darkText = Color(0xFF252B3A);
  static const Color greyText = Color(0xFF7D8597);
  static const Color borderColor = Color(0xFFE0E3EA);

  final TextEditingController _cercaController = TextEditingController();
  Timer? _debounce;

  // non tutti gli stati portano i posti liberi, quindi teniamo l'ultimo
  // valore ricevuto; null finche' non arriva il primo caricamento
  int? _postiLiberi;

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
      context.read<InvitaUtentiBloc>().add(
        InvitabiliRichiesti(idPartita: widget.idPartita, cerca: testo.trim()),
      );
    });
  }

  void _ricarica() {
    context.read<InvitaUtentiBloc>().add(
      InvitabiliRichiesti(
        idPartita: widget.idPartita,
        cerca: _cercaController.text.trim(),
      ),
    );
  }

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
                // header e campo di ricerca restano fuori dal builder: cosi'
                // il campo non viene ricreato a ogni stato e non perde il focus
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    r.horizontalPadding,
                    16,
                    r.horizontalPadding,
                    0,
                  ),
                  child: _buildHeader(context, r),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    r.horizontalPadding,
                    16,
                    r.horizontalPadding,
                    0,
                  ),
                  child: _buildRicerca(r),
                ),
                Expanded(
                  child: BlocConsumer<InvitaUtentiBloc, InvitaUtentiState>(
                    listener: (context, state) {
                      if (state is InvitabiliCaricati) {
                        setState(() {
                          _postiLiberi = state.postiLiberi;
                        });
                        // un altro giocatore puo' aver preso l'ultimo posto:
                        // true dice al dettaglio di ricaricarsi
                        if (state.alCompleto) {
                          Navigator.pop(context, true);
                        }
                      }
                      if (state is InvitoRiuscito) {
                        setState(() {
                          _postiLiberi = state.postiLiberi;
                        });
                        _mostraSnackBar(context, r, 'Utente invitato');
                        if (state.alCompleto) {
                          _mostraSnackBar(
                            context,
                            r,
                            'La partita è al completo',
                          );
                          Navigator.pop(context, true);
                        }
                      }
                      // dopo l'errore il BLoC ricarica la lista da solo,
                      // qui basta avvisare l'utente
                      if (state is InvitoErrore) {
                        _mostraSnackBar(context, r, state.messaggio);
                      }
                    },
                    builder: (context, state) {
                      if (state is InvitabiliErrore) {
                        return _buildErrore(r, state.messaggio);
                      }

                      if (state is InvitabiliCaricati) {
                        return _buildLista(r, state.utenti, null);
                      }

                      // durante l'invito la lista resta a schermo e solo il
                      // bottone dell'utente scelto mostra lo spinner
                      if (state is InvitoInCorso) {
                        return _buildLista(r, state.utenti, state.telefono);
                      }

                      if (state is InvitoRiuscito) {
                        return _buildLista(r, state.utenti, null);
                      }

                      if (state is InvitoErrore) {
                        return _buildLista(r, state.utenti, null);
                      }

                      // InvitaUtentiInitial e InvitaUtentiLoading
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
    String posti = '';
    if (_postiLiberi != null) {
      posti = '$_postiLiberi posti liberi';
      if (_postiLiberi == 1) {
        posti = '1 posto libero';
      }
    }

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invita giocatori',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: r.font(24),
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              if (posti.isNotEmpty)
                Text(
                  posti,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: r.font(14),
                    fontWeight: FontWeight.w500,
                    color: greyText,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // RICERCA
  // =====================================================================

  Widget _buildRicerca(_Responsive r) {
    return TextField(
      controller: _cercaController,
      onChanged: _onCercaCambiata,
      textInputAction: TextInputAction.search,
      style: TextStyle(fontSize: r.font(16), color: darkText),
      decoration: InputDecoration(
        hintText: 'Cerca per nome',
        hintStyle: const TextStyle(color: Color(0xFFA0A5AF)),
        prefixIcon: const Icon(Icons.search, color: primaryColor),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: r.width * 0.045,
          vertical: (r.height * 0.018).clamp(12.0, 18.0),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  // =====================================================================
  // ERRORE
  // =====================================================================

  Widget _buildErrore(_Responsive r, String messaggio) {
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
              onPressed: _ricarica,
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
  // LISTA UTENTI
  // =====================================================================

  // telefonoInInvito e' l'utente che si sta invitando, null quando non c'e'
  // nessun invito in corso
  Widget _buildLista(
    _Responsive r,
    List<UtenteInvitabile> utenti,
    String? telefonoInInvito,
  ) {
    final List<Widget> elementi = [];

    if (utenti.isEmpty) {
      elementi.add(_buildVuota(r));
    }

    for (final utente in utenti) {
      elementi.add(_buildUtenteCard(r, utente, telefonoInInvito));
      elementi.add(const SizedBox(height: 12));
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        r.horizontalPadding,
        18,
        r.horizontalPadding,
        16,
      ),
      // trascinando la lista la tastiera si chiude
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: elementi,
    );
  }

  Widget _buildVuota(_Responsive r) {
    return _buildCard(
      r: r,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            _iconBox(r, Icons.person_search_outlined),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Nessun utente trovato',
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
  // CARD UTENTE
  // =====================================================================

  Widget _buildUtenteCard(
    _Responsive r,
    UtenteInvitabile utente,
    String? telefonoInInvito,
  ) {
    final String nomeCompleto = '${utente.nome} ${utente.cognome}'.trim();

    return _buildCard(
      r: r,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
        child: Row(
          children: [
            _iconBox(r, Icons.person_outline),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nomeCompleto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: r.font(16),
                      fontWeight: FontWeight.w600,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Livello ${utente.livello.toStringAsFixed(1)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: r.font(13),
                      fontWeight: FontWeight.w500,
                      color: greyText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _bottoneInvita(r, utente.telefono, telefonoInInvito),
          ],
        ),
      ),
    );
  }

  Widget _bottoneInvita(
    _Responsive r,
    String telefono,
    String? telefonoInInvito,
  ) {
    final bool inInvito = telefono == telefonoInInvito;
    // mentre un invito e' in corso blocchiamo tutti i bottoni, cosi' non
    // partono due inviti insieme; lo spinner pero' va solo su quello scelto
    final bool bloccato = telefonoInInvito != null;
    final double altezza = (r.height * 0.05).clamp(38.0, 46.0);

    return SizedBox(
      height: altezza,
      child: ElevatedButton(
        onPressed:
            bloccato
                ? null
                : () {
                  context.read<InvitaUtentiBloc>().add(
                    InvitoRichiesto(
                      idPartita: widget.idPartita,
                      telefono: telefono,
                    ),
                  );
                },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          disabledBackgroundColor: const Color(0xFF9AA8C8),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 3,
          shadowColor: primaryColor.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child:
            inInvito
                ? SizedBox(
                  width: r.font(20),
                  height: r.font(20),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                : Text(
                  'Invita',
                  style: TextStyle(
                    fontSize: r.font(15),
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
}
