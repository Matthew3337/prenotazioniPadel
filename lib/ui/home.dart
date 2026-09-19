import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:thepadel/bloc/homePage/homeBloc.dart';
import 'package:thepadel/bloc/homePage/homeEvent.dart';
import 'package:thepadel/bloc/homePage/homeState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/prenotazione.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (_) => sl<HomeBloc>()
        ..add(const HomeProssimaPartitaRequested())
        ..add(const HomeSlotOggiRequested()),
      child: const _HomeView(),
    );
  }
}

/// Helper responsive: calcola una dimensione proporzionale alla larghezza
/// dello schermo, con un minimo e un massimo per evitare che diventi
/// troppo piccola su schermi stretti o eccessiva su tablet/desktop.
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
        // scala i font in base alla larghezza, ancorata a un iPhone
        // standard (~390px) e clampata per non esagerare su tablet
        // o rimpicciolire troppo su telefoni piccoli (iPhone SE ~375px)
        textScale =
            (MediaQuery.sizeOf(context).width / 390).clamp(0.8, 1.1);

  double font(double base) => base * textScale;

  // Padding orizzontale: percentuale della larghezza, clampata
  double get horizontalPadding => (width * 0.06).clamp(20.0, 48.0);

  double get cardBorderRadius => isTablet ? 32 : 26;

  // Larghezza massima del contenuto su schermi larghi (tablet/desktop)
  double get maxContentWidth => isTablet ? 640 : double.infinity;
}

class _HomeView extends StatelessWidget {
  const _HomeView();

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
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: r.maxContentWidth,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        r.horizontalPadding,
                        16,
                        r.horizontalPadding,
                        16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(r),
                          const SizedBox(height: 22),
                          _buildProssimaPartita(context, r),
                          const SizedBox(height: 18),
                          _buildCampiLiberi(r),
                          const SizedBox(height: 18),
                          _buildClassifica(r),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildBottomNavigation(context, r),
        ],
      ),
    );
  }

  // =====================================================================
  // HEADER
  // =====================================================================

  Widget _buildHeader(_Responsive r) {
    final avatarSize = (r.width * 0.13).clamp(48.0, 60.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ciao,',
                style: TextStyle(
                  fontSize: r.font(17),
                  fontWeight: FontWeight.w500,
                  color: greyText,
                ),
              ),
              Text(
                'Matteo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: r.font(26),
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: const BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_outline,
            color: Colors.white,
            size: avatarSize * 0.5,
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // PROSSIMA PARTITA
  // =====================================================================

  Widget _buildProssimaPartita(BuildContext context, _Responsive r) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final sectionState = state.prossimaPartita;

        if (sectionState is SectionLoading) {
          return _buildCard(
            r: r,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            ),
          );
        }

        if (sectionState is SectionError<Prenotazione>) {
          return _buildCard(
            r: r,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: r.font(26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sectionState.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: greyText, fontSize: r.font(14)),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      context
                          .read<HomeBloc>()
                          .add(const HomeProssimaPartitaRequested());
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

        if (sectionState is SectionEmpty) {
          return _buildCard(
            r: r,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Prossima partita',
                    style: TextStyle(
                      fontSize: r.font(17),
                      fontWeight: FontWeight.w500,
                      color: greyText,
                    ),
                  ),
                  SizedBox(height: 18),
                  Row(
                    children: [
                      _iconBox(r, Icons.calendar_month_outlined),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Non hai ancora una partita prenotata',
                          style: TextStyle(
                            fontSize: r.font(17),
                            fontWeight: FontWeight.w500,
                            color: darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        if (sectionState is SectionSuccess<Prenotazione>) {
          return _buildPartitaCard(sectionState.data, r);
        }

        return const SizedBox.shrink();
      },
    );
  }

  // =====================================================================
  // CARD PARTITA
  // =====================================================================

  Widget _buildPartitaCard(Prenotazione partita, _Responsive r) {
    final String giorno = _giornoSettimana(partita.dataPrenotazione);
    final String data = _formatData(partita.dataPrenotazione);
    final String oraInizio = _formatTime(partita.oraInizio);
    final String oraFine = _formatTime(partita.oraFine);

    final List<String?> giocatori = [
      partita.telefonoGiocatore1,
      partita.telefonoGiocatore2,
      partita.telefonoGiocatore3,
      partita.telefonoGiocatore4,
    ];
    final int numeroGiocatori = giocatori.where((id) => id != null).length;

    return _buildCard(
      r: r,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Prossima partita',
              style: TextStyle(
                fontSize: r.font(17),
                fontWeight: FontWeight.w500,
                color: greyText,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _iconBox(r, Icons.calendar_month_outlined),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Campo ${partita.idCampo} · $giorno $oraInizio',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: r.font(16),
                          fontWeight: FontWeight.w600,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$data · $oraInizio - $oraFine',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: r.font(13),
                          fontWeight: FontWeight.w500,
                          color: greyText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$numeroGiocatori giocatori',
                        style: TextStyle(
                          fontSize: r.font(12),
                          color: greyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // SLOT DISPONIBILI
  // =====================================================================

  Widget _buildCampiLiberi(_Responsive r) {
    return _buildCard(
      r: r,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Slot disponibili oggi',
                  style: TextStyle(
                    fontSize: r.font(17),
                    fontWeight: FontWeight.w500,
                    color: greyText,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: apertura selezione data
                  },
                  child: Text(
                    'Vedi altri giorni',
                    style: TextStyle(
                      fontSize: r.font(14),
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildSlotSection(r),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotSection(_Responsive r) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final sectionState = state.slotOggi;

        if (sectionState is SectionLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: primaryColor),
            ),
          );
        }

        if (sectionState is SectionError<List<SlotOrario>>) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: r.font(26),
                ),
                const SizedBox(height: 8),
                Text(
                  sectionState.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: greyText, fontSize: r.font(14)),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    context.read<HomeBloc>().add(const HomeSlotOggiRequested());
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
          );
        }

        if (sectionState is SectionEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Nessuno slot disponibile per oggi',
              style: TextStyle(fontSize: r.font(14), color: greyText),
            ),
          );
        }

        if (sectionState is SectionSuccess<List<SlotOrario>>) {
          final slotPerCampo = _raggruppaPerCampo(sectionState.data);

          if (slotPerCampo.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Nessuno slot disponibile per oggi',
                style: TextStyle(fontSize: r.font(14), color: greyText),
              ),
            );
          }

          final ultimoCampo = slotPerCampo.keys.last;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: slotPerCampo.entries.map((entry) {
              final isLast = entry.key == ultimoCampo;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.key, // nome del campo, es. "Campo 1"
                      style: TextStyle(
                        fontSize: r.font(15),
                        fontWeight: FontWeight.w600,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: (r.width * 0.11).clamp(40.0, 48.0),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: entry.value.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) =>
                            _slotChip(r, entry.value[index]),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // Raggruppa gli slot per nome campo mantenendo l'ordine con cui arrivano
  // dal repository (che gia' li ordina per orario crescente).
  Map<String, List<SlotOrario>> _raggruppaPerCampo(List<SlotOrario> slots) {
    final Map<String, List<SlotOrario>> risultato = {};
    for (final slot in slots) {
      risultato.putIfAbsent(slot.nomeCampo, () => []).add(slot);
    }
    return risultato;
  }

  Widget _slotChip(_Responsive r, SlotOrario slot) {
    final Color background = slot.disponibile
        ? const Color(0xFFE0F4EE) // verde chiaro
        : const Color(0xFFFBE3E3); // rosso chiaro
    final Color textColor = slot.disponibile
        ? const Color(0xFF075E50)
        : const Color(0xFFA33A3A);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        // TODO: avvio flusso creazione prenotazione per questo slot
        // (slot.idCampo, slot.oraInizio, slot.oraFine)
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${slot.oraInizio} - ${slot.oraFine}',
          style: TextStyle(
            color: textColor,
            fontSize: r.font(13),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // CLASSIFICA
  // =====================================================================

  Widget _buildClassifica(_Responsive r) {
    final badgeSize = (r.width * 0.12).clamp(44.0, 54.0);

    return _buildCard(
      r: r,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'La tua posizione',
                  style: TextStyle(
                    fontSize: r.font(17),
                    fontWeight: FontWeight.w500,
                    color: greyText,
                  ),
                ),
                Flexible(
                  child: GestureDetector(
                    onTap: () {
                      // TODO
                    },
                    child: Text(
                      'Classifica completa',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: r.font(14),
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0D9),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '4',
                      style: TextStyle(
                        fontSize: r.font(18),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF92530B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Punteggio: 1240',
                  style: TextStyle(
                    fontSize: r.font(15),
                    fontWeight: FontWeight.w500,
                    color: darkText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // BOTTOM NAVIGATION
  // =====================================================================

Widget _buildBottomNavigation(BuildContext context, _Responsive r) {
  return SafeArea(
    top: false,
    left: false,
    right: false,
    minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Container(
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _navItem(
            r,
            icon: Icons.home_outlined,
            label: 'Home',
            selected: true,
          ),
          _navItem(
            r,
            icon: Icons.calendar_month_outlined,
            label: 'Prenota',
            selected: false,
          ),
          _navItem(
            r,
            icon: Icons.history,
            label: 'Storico',
            selected: false,
          ),
          _navItem(
            r,
            icon: Icons.bar_chart_outlined,
            label: 'Classifica',
            selected: false,
          ),
        ],
      ),
    ),
  );
}

Widget _navItem(_Responsive r, {required IconData icon, required String label, required bool selected,}) {
  return Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () {
        // TODO: cambio pagina
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: r.font(26),
            color: selected
                ? primaryColor
                : const Color(0xFFA6ACB9),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: r.font(12),
              fontWeight: selected
                  ? FontWeight.w600
                  : FontWeight.w500,
              color: selected
                  ? primaryColor
                  : const Color(0xFFA6ACB9),
            ),
          ),
        ],
      ),
    ),
  );
}

  // =====================================================================
  // CARD GENERICA
  // =====================================================================

  Widget _iconBox(_Responsive r, IconData icon) {
    final size = (r.width * 0.19).clamp(58.0, 76.0);
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
      constraints: const BoxConstraints(minHeight: 0),
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