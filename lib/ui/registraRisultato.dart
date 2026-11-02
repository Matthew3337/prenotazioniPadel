import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:thepadel/bloc/registraRisultato/registraRisultatoBloc.dart';
import 'package:thepadel/bloc/registraRisultato/registraRisultatoEvent.dart';
import 'package:thepadel/bloc/registraRisultato/registraRisultatoState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';

class RegistraRisultatoPage extends StatelessWidget {
  final DettaglioPartita dettaglio;

  const RegistraRisultatoPage({super.key, required this.dettaglio});

  @override
  Widget build(BuildContext context) {
    // nessun evento iniziale: la richiesta parte solo quando l'utente
    // tocca "Salva risultato"
    return BlocProvider<RegistraRisultatoBloc>(
      create: (_) => sl<RegistraRisultatoBloc>(),
      child: _RegistraRisultatoView(dettaglio: dettaglio),
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

class _RegistraRisultatoView extends StatefulWidget {
  final DettaglioPartita dettaglio;

  const _RegistraRisultatoView({required this.dettaglio});

  @override
  State<_RegistraRisultatoView> createState() => _RegistraRisultatoViewState();
}

class _RegistraRisultatoViewState extends State<_RegistraRisultatoView> {
  static const Color backgroundColor = Color(0xFFF7F8FC);
  static const Color primaryColor = Color(0xFF4564B1);
  static const Color darkText = Color(0xFF252B3A);
  static const Color greyText = Color(0xFF7D8597);
  static const Color borderColor = Color(0xFFE0E3EA);

  static const int maxGame = 6;

  // per ogni posto, nello stesso ordine di dettaglio.posti, la squadra
  // scelta: 1 o 2
  final List<int> _squadre = [];

  // i game dei tre set: la posizione nella lista e' il numero del set
  final List<int> _gameSquadra1 = [0, 0, 0];
  final List<int> _gameSquadra2 = [0, 0, 0];

  bool _terzoSetGiocato = false;

  @override
  void initState() {
    super.initState();
    // all'inizio i primi due posti stanno in squadra 1 e gli altri in squadra 2
    for (int i = 0; i < widget.dettaglio.posti.length; i++) {
      if (i < 2) {
        _squadre.add(1);
      } else {
        _squadre.add(2);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _Responsive(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: BlocConsumer<RegistraRisultatoBloc, RegistraRisultatoState>(
          listener: (context, state) {
            if (state is RisultatoRegistrato) {
              _mostraSnackBar(context, r, 'Risultato registrato');
              // true dice al dettaglio di ricaricarsi
              Navigator.pop(context, true);
            }
            if (state is RegistraRisultatoErrore) {
              _mostraSnackBar(context, r, state.messaggio);
            }
          },
          builder: (context, state) {
            final bool isLoading = state is RegistraRisultatoLoading;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                child:
                    _registrazioneDisponibile()
                        ? _buildForm(context, r, isLoading)
                        : _buildNonDisponibile(context, r),
              ),
            );
          },
        ),
      ),
    );
  }

  // senza idPosto non possiamo comporre le squadre: succede se il server
  // non e' ancora aggiornato e non manda il campo
  bool _registrazioneDisponibile() {
    for (final posto in widget.dettaglio.posti) {
      if (posto.idPosto == null) {
        return false;
      }
    }
    return true;
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
            'Registra risultato',
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
  // REGISTRAZIONE NON DISPONIBILE
  // =====================================================================

  Widget _buildNonDisponibile(BuildContext context, _Responsive r) {
    return Column(
      children: [
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
          child: Center(
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
                    'Registrazione del risultato non disponibile al momento',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: greyText, fontSize: r.font(15)),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Torna indietro',
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
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // FORM
  // =====================================================================

  Widget _buildForm(BuildContext context, _Responsive r, bool isLoading) {
    return Column(
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
                _buildSquadre(r, isLoading),
                const SizedBox(height: 18),
                _buildSet(r, isLoading),
              ],
            ),
          ),
        ),
        _buildBottoneSalva(context, r, isLoading),
      ],
    );
  }

  // =====================================================================
  // SQUADRE
  // =====================================================================

  Widget _buildSquadre(_Responsive r, bool isLoading) {
    return _buildCard(
      r: r,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Squadre',
              style: TextStyle(
                fontSize: r.font(17),
                fontWeight: FontWeight.w500,
                color: greyText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tocca un giocatore per spostarlo nell\'altra squadra',
              style: TextStyle(fontSize: r.font(13), color: greyText),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _colonnaSquadra(r, 1, isLoading)),
                const SizedBox(width: 12),
                Expanded(child: _colonnaSquadra(r, 2, isLoading)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _colonnaSquadra(_Responsive r, int squadra, bool isLoading) {
    final List<Widget> righe = [
      Text(
        'Squadra $squadra',
        style: TextStyle(
          fontSize: r.font(15),
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
      ),
    ];

    for (int i = 0; i < _squadre.length; i++) {
      if (_squadre[i] == squadra) {
        righe.add(const SizedBox(height: 10));
        righe.add(_rigaGiocatore(r, i, isLoading));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: righe,
    );
  }

  Widget _rigaGiocatore(_Responsive r, int indice, bool isLoading) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      // durante l'invio le squadre restano bloccate
      onTap:
          isLoading
              ? null
              : () {
                _cambiaSquadra(indice);
              },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _nomeGiocatore(widget.dettaglio.posti[indice]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: r.font(14),
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.swap_horiz, color: greyText, size: r.font(20)),
          ],
        ),
      ),
    );
  }

  String _nomeGiocatore(PostoPartita posto) {
    if (posto.tipo == 'CAMPO') {
      return 'Giocatore del campo';
    }
    return '${posto.nome ?? ''} ${posto.cognome ?? ''}'.trim();
  }

  void _cambiaSquadra(int indice) {
    setState(() {
      if (_squadre[indice] == 1) {
        _squadre[indice] = 2;
      } else {
        _squadre[indice] = 1;
      }
    });
  }

  // =====================================================================
  // SET
  // =====================================================================

  Widget _buildSet(_Responsive r, bool isLoading) {
    return _buildCard(
      r: r,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set',
              style: TextStyle(
                fontSize: r.font(17),
                fontWeight: FontWeight.w500,
                color: greyText,
              ),
            ),
            const SizedBox(height: 14),
            _rigaSet(r, 'Set 1', 0, !isLoading),
            const SizedBox(height: 14),
            _rigaSet(r, 'Set 2', 1, !isLoading),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Terzo set giocato',
                    style: TextStyle(
                      fontSize: r.font(15),
                      fontWeight: FontWeight.w600,
                      color: darkText,
                    ),
                  ),
                ),
                Switch(
                  value: _terzoSetGiocato,
                  activeTrackColor: primaryColor,
                  onChanged:
                      isLoading
                          ? null
                          : (valore) {
                            setState(() {
                              _terzoSetGiocato = valore;
                            });
                          },
                ),
              ],
            ),
            const SizedBox(height: 10),
            _rigaSet(
              r,
              'Set 3 (se giocato)',
              2,
              _terzoSetGiocato && !isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _rigaSet(_Responsive r, String titolo, int indiceSet, bool abilitato) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          titolo,
          style: TextStyle(
            fontSize: r.font(15),
            fontWeight: FontWeight.w600,
            color: abilitato ? darkText : greyText,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _stepperGame(r, indiceSet, 1, abilitato)),
            const SizedBox(width: 12),
            Expanded(child: _stepperGame(r, indiceSet, 2, abilitato)),
          ],
        ),
      ],
    );
  }

  Widget _stepperGame(
    _Responsive r,
    int indiceSet,
    int squadra,
    bool abilitato,
  ) {
    int valore = _gameSquadra1[indiceSet];
    if (squadra == 2) {
      valore = _gameSquadra2[indiceSet];
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Squadra $squadra',
          style: TextStyle(fontSize: r.font(13), color: greyText),
        ),
        Row(
          children: [
            _bottoneStepper(
              r,
              icona: Icons.remove,
              abilitato: abilitato && valore > 0,
              onPressed: () {
                _cambiaGame(indiceSet, squadra, valore - 1);
              },
            ),
            Expanded(
              child: Text(
                '$valore',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: r.font(18),
                  fontWeight: FontWeight.w700,
                  color: abilitato ? darkText : greyText,
                ),
              ),
            ),
            _bottoneStepper(
              r,
              icona: Icons.add,
              abilitato: abilitato && valore < maxGame,
              onPressed: () {
                _cambiaGame(indiceSet, squadra, valore + 1);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _bottoneStepper(
    _Responsive r, {
    required IconData icona,
    required bool abilitato,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      // con onPressed a null il bottone si disabilita da solo
      onPressed: abilitato ? onPressed : null,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      color: primaryColor,
      disabledColor: borderColor,
      icon: Icon(icona, size: r.font(20)),
    );
  }

  void _cambiaGame(int indiceSet, int squadra, int nuovoValore) {
    setState(() {
      if (squadra == 1) {
        _gameSquadra1[indiceSet] = nuovoValore;
      } else {
        _gameSquadra2[indiceSet] = nuovoValore;
      }
    });
  }

  // =====================================================================
  // BOTTONE SALVA
  // =====================================================================

  // i controlli su squadre e set li fa il BLoC: qui raccogliamo solo i dati
  void _salva(BuildContext context) {
    final List<int> squadra1 = [];
    final List<int> squadra2 = [];

    for (int i = 0; i < _squadre.length; i++) {
      final int? idPosto = widget.dettaglio.posti[i].idPosto;
      if (idPosto != null) {
        if (_squadre[i] == 1) {
          squadra1.add(idPosto);
        } else {
          squadra2.add(idPosto);
        }
      }
    }

    final List<SetPartita> set = [
      SetPartita(squadra1: _gameSquadra1[0], squadra2: _gameSquadra2[0]),
      SetPartita(squadra1: _gameSquadra1[1], squadra2: _gameSquadra2[1]),
    ];
    if (_terzoSetGiocato) {
      set.add(
        SetPartita(squadra1: _gameSquadra1[2], squadra2: _gameSquadra2[2]),
      );
    }

    context.read<RegistraRisultatoBloc>().add(
      RegistraRisultatoRichiesto(
        idPartita: widget.dettaglio.id,
        squadra1: squadra1,
        squadra2: squadra2,
        set: set,
      ),
    );
  }

  Widget _buildBottoneSalva(
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
          onPressed:
              isLoading
                  ? null
                  : () {
                    _salva(context);
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
              isLoading
                  ? SizedBox(
                    width: r.font(22),
                    height: r.font(22),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                  : Text(
                    'Salva risultato',
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
