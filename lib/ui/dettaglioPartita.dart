import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaBloc.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaEvent.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';

class DettaglioPartitaPage extends StatelessWidget {
  final int idPartita;

  const DettaglioPartitaPage({super.key, required this.idPartita});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DettaglioPartitaBloc>(
      create:
          (_) =>
              sl<DettaglioPartitaBloc>()
                ..add(DettaglioPartitaRichiesto(idPartita: idPartita)),
      child: _DettaglioPartitaView(idPartita: idPartita),
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

class _DettaglioPartitaView extends StatelessWidget {
  // serve per rimandare l'evento quando l'utente tocca "Riprova"
  final int idPartita;

  const _DettaglioPartitaView({required this.idPartita});

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
                  child:
                      BlocConsumer<DettaglioPartitaBloc, DettaglioPartitaState>(
                        listener: (context, state) {
                          // true dice alla pagina precedente di ricaricarsi,
                          // perche' la partita non e' piu' la stessa
                          if (state is PartitaEliminata) {
                            _mostraSnackBar(context, r, 'Partita eliminata');
                            Navigator.pop(context, true);
                          }
                          if (state is UscitaCompletata) {
                            _mostraSnackBar(
                              context,
                              r,
                              'Sei uscito dalla partita',
                            );
                            Navigator.pop(context, true);
                          }
                          if (state is OperazioneErrore) {
                            _mostraSnackBar(context, r, state.messaggio);
                          }
                        },
                        builder: (context, state) {
                          if (state is DettaglioPartitaErrore) {
                            return _buildErrore(context, r, state.messaggio);
                          }

                          if (state is DettaglioPartitaCaricato) {
                            return _buildContenuto(
                              context,
                              r,
                              state.dettaglio,
                              false,
                            );
                          }

                          // durante l'operazione il dettaglio resta a
                          // schermo, ma con i bottoni bloccati
                          if (state is OperazioneInCorso) {
                            return _buildContenuto(
                              context,
                              r,
                              state.dettaglio,
                              true,
                            );
                          }

                          // dopo l'errore il BLoC ricarica da solo il
                          // dettaglio, intanto mostriamo quello che avevamo
                          if (state is OperazioneErrore) {
                            return _buildContenuto(
                              context,
                              r,
                              state.dettaglio,
                              false,
                            );
                          }

                          // PartitaEliminata e UscitaCompletata durano solo
                          // il tempo del pop, quindi basta lo spinner

                          // e lo stesso vale per Initial e Loading
                          return const Center(
                            child: CircularProgressIndicator(
                              color: primaryColor,
                            ),
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
            'Dettaglio partita',
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
                context.read<DettaglioPartitaBloc>().add(
                  DettaglioPartitaRichiesto(idPartita: idPartita),
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
  // CONTENUTO
  // =====================================================================

  Widget _buildContenuto(
    BuildContext context,
    _Responsive r,
    DettaglioPartita dettaglio,
    bool operazioneInCorso,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        r.horizontalPadding,
        22,
        r.horizontalPadding,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfo(r, dettaglio),
          const SizedBox(height: 18),
          _buildGiocatori(r, dettaglio),
          const SizedBox(height: 18),
          _buildAzioni(context, r, dettaglio, operazioneInCorso),
        ],
      ),
    );
  }

  // =====================================================================
  // INFO PARTITA
  // =====================================================================

  Widget _buildInfo(_Responsive r, DettaglioPartita dettaglio) {
    final String giorno = _giornoSettimana(dettaglio.dataPartita);
    final String data = _formatData(dettaglio.dataPartita);
    final String oraInizio = _formatTime(dettaglio.oraInizio);
    final String oraFine = _formatTime(dettaglio.oraFine);

    String tipo = 'Privata';
    if (dettaglio.tipo == 'PUBBLICA') {
      tipo = 'Pubblica';
    }

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
                    'Partita',
                    style: TextStyle(
                      fontSize: r.font(17),
                      fontWeight: FontWeight.w500,
                      color: greyText,
                    ),
                  ),
                ),
                _badgeStato(r, dettaglio.stato),
              ],
            ),
            const SizedBox(height: 14),
            _rigaInfo(
              r,
              icona: Icons.sports_tennis,
              etichetta: 'Campo',
              valore: dettaglio.nomeCampo,
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
              icona:
                  dettaglio.tipo == 'PUBBLICA'
                      ? Icons.public
                      : Icons.lock_outline,
              etichetta: 'Tipo',
              valore: tipo,
            ),
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

  // il server manda lo stato in minuscolo: qui scegliamo testo e colori
  // del badge, riusando le tinte verde e rossa degli slot in home
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
      colore = const Color(0xFF075E50);
    }
    if (stato == 'annullata') {
      testo = 'Annullata';
      sfondo = const Color(0xFFFBE3E3);
      colore = const Color(0xFFA33A3A);
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
  // GIOCATORI
  // =====================================================================

  Widget _buildGiocatori(_Responsive r, DettaglioPartita dettaglio) {
    final List<Widget> righe = [];

    for (final posto in dettaglio.posti) {
      righe.add(_rigaPostoOccupato(r, posto, dettaglio.telefonoCreatore));
      righe.add(const SizedBox(height: 12));
    }

    // il server manda solo i posti occupati, gli altri fino a 4 sono liberi
    for (int i = 0; i < dettaglio.postiLiberi; i++) {
      righe.add(_rigaPostoLibero(r));
      righe.add(const SizedBox(height: 12));
    }

    // tolgo lo spazio dopo l'ultima riga
    if (righe.isNotEmpty) {
      righe.removeLast();
    }

    return _buildCard(
      r: r,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Giocatori',
              style: TextStyle(
                fontSize: r.font(17),
                fontWeight: FontWeight.w500,
                color: greyText,
              ),
            ),
            const SizedBox(height: 14),
            ...righe,
          ],
        ),
      ),
    );
  }

  Widget _rigaPostoOccupato(
    _Responsive r,
    PostoPartita posto,
    String telefonoCreatore,
  ) {
    if (posto.tipo == 'CAMPO') {
      return Row(
        children: [
          _iconBox(r, Icons.storefront_outlined),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Giocatore del campo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: r.font(16),
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
            ),
          ),
        ],
      );
    }

    final String nomeCompleto =
        '${posto.nome ?? ''} ${posto.cognome ?? ''}'.trim();
    final bool organizzatore = posto.telefono == telefonoCreatore;

    String dettagli = posto.confermata ? 'Confermato' : 'Da confermare';
    if (posto.livello != null) {
      dettagli = 'Livello ${posto.livello!.toStringAsFixed(1)} · $dettagli';
    }

    return Row(
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
                dettagli,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: r.font(13),
                  fontWeight: FontWeight.w500,
                  color: posto.confermata ? const Color(0xFF075E50) : greyText,
                ),
              ),
            ],
          ),
        ),
        if (organizzatore) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F1FC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Organizzatore',
              style: TextStyle(
                color: primaryColor,
                fontSize: r.font(12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _rigaPostoLibero(_Responsive r) {
    return Row(
      children: [
        _iconBox(r, Icons.person_add_alt_outlined),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Posto libero',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: r.font(16),
              fontWeight: FontWeight.w500,
              color: greyText,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // AZIONI
  // =====================================================================

  // i bottoni compaiono solo se il server dice che l'utente puo' usarli.
  // Invita, Conferma e Registra risultato per ora mostrano solo un avviso
  Widget _buildAzioni(
    BuildContext context,
    _Responsive r,
    DettaglioPartita dettaglio,
    bool operazioneInCorso,
  ) {
    final List<Widget> bottoni = [];

    void funzioneInArrivo() {
      _mostraSnackBar(context, r, 'Funzione in arrivo');
    }

    if (dettaglio.azioni.puoInvitare) {
      bottoni.add(
        _bottoneAzione(
          r,
          testo: 'Invita',
          distruttivo: false,
          disabilitato: operazioneInCorso,
          caricamento: false,
          onPressed: funzioneInArrivo,
        ),
      );
    }
    if (dettaglio.azioni.puoConfermare) {
      bottoni.add(
        _bottoneAzione(
          r,
          testo: 'Conferma',
          distruttivo: false,
          disabilitato: operazioneInCorso,
          caricamento: false,
          onPressed: funzioneInArrivo,
        ),
      );
    }
    if (dettaglio.azioni.puoRegistrareRisultato) {
      bottoni.add(
        _bottoneAzione(
          r,
          testo: 'Registra risultato',
          distruttivo: false,
          disabilitato: operazioneInCorso,
          caricamento: false,
          onPressed: funzioneInArrivo,
        ),
      );
    }
    // lo stato OperazioneInCorso non dice quale operazione e' partita:
    // lo spinner va su Esci ed Elimina, che sono gli unici bottoni che la
    // fanno partire (di solito se ne vede solo uno dei due)
    if (dettaglio.azioni.puoUscire) {
      bottoni.add(
        _bottoneAzione(
          r,
          testo: 'Esci dalla partita',
          distruttivo: false,
          disabilitato: operazioneInCorso,
          caricamento: operazioneInCorso,
          onPressed: () {
            _confermaEsci(context, dettaglio.id);
          },
        ),
      );
    }
    if (dettaglio.azioni.puoEliminare) {
      bottoni.add(
        _bottoneAzione(
          r,
          testo: 'Elimina partita',
          distruttivo: true,
          disabilitato: operazioneInCorso,
          caricamento: operazioneInCorso,
          onPressed: () {
            _confermaElimina(context, dettaglio.id);
          },
        ),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: bottoni);
  }

  Future<void> _confermaElimina(BuildContext context, int idPartita) async {
    final bool confermato = await _chiediConferma(
      context,
      titolo: 'Eliminare la partita?',
      testo: 'La partita verrà annullata per tutti i partecipanti.',
    );

    if (confermato && context.mounted) {
      context.read<DettaglioPartitaBloc>().add(
        EliminaPartitaRichiesta(idPartita: idPartita),
      );
    }
  }

  Future<void> _confermaEsci(BuildContext context, int idPartita) async {
    final bool confermato = await _chiediConferma(
      context,
      titolo: 'Uscire dalla partita?',
      testo: 'Il tuo posto tornerà libero.',
    );

    if (confermato && context.mounted) {
      context.read<DettaglioPartitaBloc>().add(
        EsciDaPartitaRichiesta(idPartita: idPartita),
      );
    }
  }

  // restituisce true solo se l'utente tocca Conferma; con Annulla o
  // toccando fuori dal dialog non succede niente
  Future<bool> _chiediConferma(
    BuildContext context, {
    required String titolo,
    required String testo,
  }) async {
    final r = _Responsive(context);

    final bool? risposta = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r.cardBorderRadius),
          ),
          title: Text(
            titolo,
            style: TextStyle(
              fontSize: r.font(20),
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          content: Text(
            testo,
            style: TextStyle(fontSize: r.font(15), color: greyText),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                'Annulla',
                style: TextStyle(
                  color: greyText,
                  fontWeight: FontWeight.w600,
                  fontSize: r.font(15),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(
                'Conferma',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: r.font(15),
                ),
              ),
            ),
          ],
        );
      },
    );

    return risposta == true;
  }

  Widget _bottoneAzione(
    _Responsive r, {
    required String testo,
    required bool distruttivo,
    required bool disabilitato,
    required bool caricamento,
    required VoidCallback onPressed,
  }) {
    final double altezza = (r.height * 0.065).clamp(48.0, 60.0);
    const Color rosso = Color(0xFFA33A3A);

    Widget contenuto = Text(
      testo,
      style: TextStyle(
        fontSize: r.font(16),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
    if (caricamento) {
      contenuto = SizedBox(
        width: r.font(22),
        height: r.font(22),
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: distruttivo ? rosso : Colors.white,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: altezza,
        child: ElevatedButton(
          // con onPressed a null il bottone si disabilita da solo
          onPressed: disabilitato ? null : onPressed,
          // il bottone distruttivo e' bianco con bordo e testo rossi,
          // cosi' si distingue subito dagli altri. I colori da disabilitato
          // restano quasi gli stessi, cosi' lo spinner si vede bene
          style: ElevatedButton.styleFrom(
            backgroundColor: distruttivo ? Colors.white : primaryColor,
            foregroundColor: distruttivo ? rosso : Colors.white,
            disabledBackgroundColor:
                distruttivo
                    ? Colors.white
                    : primaryColor.withValues(alpha: 0.6),
            disabledForegroundColor:
                distruttivo ? rosso.withValues(alpha: 0.6) : Colors.white,
            elevation: distruttivo ? 0 : 3,
            shadowColor: primaryColor.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side:
                  distruttivo
                      ? const BorderSide(color: rosso, width: 1.5)
                      : BorderSide.none,
            ),
          ),
          child: contenuto,
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
