import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/prenota/prenotaBloc.dart';
import 'package:thepadel/bloc/prenota/prenotaEvent.dart';
import 'package:thepadel/bloc/prenota/prenotaState.dart';
import 'package:thepadel/domainLayer/enetity/campo.dart';
import 'package:thepadel/domainLayer/enetity/partitaStorico.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';

import 'stileApp.dart';

// La barra dei giorni e il tabellone degli slot stanno qui perche' servono sia
// a chi prenota sia all'admin che crea una partita. Lo slot scelto resta nella
// pagina: qui arrivano solo i dati da disegnare e le funzioni da chiamare.

class BarraGiorni extends StatelessWidget {
  final PrenotaState state;
  final ValueChanged<DateTime> onGiornoScelto;

  const BarraGiorni({
    super.key,
    required this.state,
    required this.onGiornoScelto,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    const List<String> sigle = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

    final List<Widget> caselle = [];
    for (int i = 0; i < state.giorni.length; i++) {
      final DateTime giorno = state.giorni[i];
      final bool attivo = giorno == state.giorno;
      if (i > 0) {
        caselle.add(const SizedBox(width: 4));
      }
      caselle.add(
        Expanded(
          child: Semantics(
            selected: attivo,
            label: dataEstesa(giorno),
            child: Material(
              color: attivo ? Colori.primario : Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side:
                    attivo
                        ? BorderSide.none
                        : const BorderSide(color: Colori.bordo),
              ),
              child: InkWell(
                onTap: () {
                  onGiornoScelto(giorno);
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sigle[giorno.weekday - 1],
                        style: stileTesto(
                          r,
                          base: 12,
                          peso: FontWeight.w600,
                          colore: attivo ? Colors.white : Colori.testo,
                        ),
                      ),
                      Text(
                        '${giorno.day}',
                        style: stileNumero(r, 18).copyWith(
                          color: attivo ? Colors.white : Colori.testo,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(children: caselle);
  }
}

class TabelloneSlot extends StatelessWidget {
  final PrenotaState state;
  final SlotOrario? slotScelto;
  // riceve null quando si tocca di nuovo lo slot gia' scelto
  final ValueChanged<SlotOrario?> onSlotCambiato;
  // l'admin non gioca: senza questa funzione la cella "La tua partita" non c'e'
  final ValueChanged<int>? onApriPartita;

  const TabelloneSlot({
    super.key,
    required this.state,
    required this.slotScelto,
    required this.onSlotCambiato,
    this.onApriPartita,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final PrenotaState stato = state;

    if (stato is PrenotaErrore) {
      return CardErrore(
        titolo:
            'Non siamo riusciti a caricare gli orari di ${nomeGiorno(stato.giorno)}',
        testo: 'Puoi riprovare o scegliere un altro giorno.',
        onRiprova: () {
          context.read<PrenotaBloc>().add(const PrenotaRichiesta());
        },
      );
    }

    if (stato is PrenotaCaricato) {
      return _buildTabellone(r, stato);
    }

    return _buildScheletro();
  }

  Widget _buildScheletro() {
    final List<Widget> righe = [];
    for (int i = 0; i < 9; i++) {
      righe.add(
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(width: 52, child: BarraGrigia(altezza: 16)),
              SizedBox(width: 6),
              Expanded(child: BarraGrigia(altezza: 48, raggio: 10)),
              SizedBox(width: 6),
              Expanded(child: BarraGrigia(altezza: 48, raggio: 10)),
            ],
          ),
        ),
      );
    }
    return CardBianca(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Column(children: righe),
    );
  }

  // I campi possono avere orari diversi: le righe sono l'unione degli orari di
  // tutti i campi, ordinati considerando che dopo mezzanotte e' gia' domani.
  List<String> _orariDelGiorno(PrenotaCaricato state) {
    final Map<String, DateTime> inizi = {};
    for (final campo in state.campi) {
      final List<SlotOrario> slots = state.slotPerCampo[campo.id] ?? [];
      for (final slot in slots) {
        inizi[oraBreve(slot.oraInizio)] = slot.inizioEffettivo(
          state.giorno,
          campo.oraApertura,
        );
      }
    }
    final List<String> orari = inizi.keys.toList();
    orari.sort((a, b) => inizi[a]!.compareTo(inizi[b]!));
    return orari;
  }

  SlotOrario? _slotDelCampo(PrenotaCaricato state, Campo campo, String ora) {
    final List<SlotOrario> slots = state.slotPerCampo[campo.id] ?? [];
    for (final slot in slots) {
      if (oraBreve(slot.oraInizio) == ora) {
        return slot;
      }
    }
    return null;
  }

  Widget _buildTabellone(Responsive r, PrenotaCaricato state) {
    final List<String> orari = _orariDelGiorno(state);

    if (orari.isEmpty) {
      return CardBianca(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Nessun orario disponibile per questo giorno.',
          style: stileSecondario(r),
        ),
      );
    }

    return CardBianca(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double colonnaOra = 52;
          const double spazio = 6;
          final int numeroCampi = state.campi.length;

          // sotto questa larghezza "La tua partita" non ci starebbe: da quel
          // punto in poi il tabellone scorre dentro il suo riquadro
          double colonnaCampo =
              (constraints.maxWidth - colonnaOra - spazio * numeroCampi) /
              numeroCampi;
          if (colonnaCampo < 88) {
            colonnaCampo = 88;
          }

          final List<Widget> intestazione = [
            const SizedBox(width: colonnaOra),
          ];
          for (final campo in state.campi) {
            intestazione.add(const SizedBox(width: spazio));
            intestazione.add(
              SizedBox(
                width: colonnaCampo,
                child: Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campo.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: stileTesto(r, peso: FontWeight.w700),
                      ),
                      Text(
                        campo.alCoperto ? 'Al coperto' : "All'aperto",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: stileSecondario(r, base: 12),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final List<Widget> righe = [
            Row(children: intestazione),
            const SizedBox(height: 8),
          ];

          final DateTime adesso = DateTime.now();
          for (int i = 0; i < orari.length; i++) {
            final List<Widget> celle = [
              SizedBox(
                width: colonnaOra,
                child: Text(
                  orari[i],
                  style: stileSecondario(r).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ];
            for (final campo in state.campi) {
              celle.add(const SizedBox(width: spazio));
              celle.add(
                SizedBox(
                  width: colonnaCampo,
                  child: _buildCella(
                    r,
                    state,
                    _slotDelCampo(state, campo, orari[i]),
                    campo,
                    adesso,
                  ),
                ),
              );
            }
            if (i > 0) {
              righe.add(const SizedBox(height: 6));
            }
            righe.add(Row(children: celle));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: righe,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCella(
    Responsive r,
    PrenotaCaricato state,
    SlotOrario? slot,
    Campo campo,
    DateTime adesso,
  ) {
    // questo campo in quest'ora e' chiuso: la casella resta vuota
    if (slot == null) {
      return const SizedBox(height: 48);
    }

    final String nomeOra = '${campo.nome}, ${oraBreve(slot.oraInizio)}';

    // l'ordine conta: una propria partita e' anche "occupata", e uno slot
    // gia' iniziato per il server puo' risultare ancora disponibile
    final ValueChanged<int>? apriPartita = onApriPartita;
    final PartitaStorico? mia = state.partitaUtenteDelloSlot(slot);
    if (mia != null && apriPartita != null) {
      return _cella(
        r,
        testo: 'La tua partita',
        descrizione: nomeOra,
        sfondo: Colori.azzurroChiaro,
        colore: Colori.azzurro,
        peso: FontWeight.w700,
        onTap: () {
          apriPartita(mia.id);
        },
      );
    }

    if (state.slotPassato(slot, adesso)) {
      return _cella(
        r,
        testo: 'Passato',
        descrizione: nomeOra,
        sfondo: Colori.sfondo,
        colore: Colori.grigio,
        peso: FontWeight.w400,
      );
    }

    if (!slot.disponibile) {
      return _cella(
        r,
        testo: 'Occupato',
        descrizione: nomeOra,
        sfondo: Colori.sfondo,
        colore: Colori.testoSecondario,
        peso: FontWeight.w400,
      );
    }

    final SlotOrario? scelto = slotScelto;
    if (scelto != null &&
        scelto.idCampo == slot.idCampo &&
        scelto.oraInizio == slot.oraInizio) {
      return _cella(
        r,
        testo: 'Scelto',
        descrizione: nomeOra,
        sfondo: Colori.primario,
        colore: Colors.white,
        peso: FontWeight.w700,
        onTap: () {
          onSlotCambiato(null);
        },
      );
    }

    return _cella(
      r,
      testo: 'Libero',
      descrizione: nomeOra,
      sfondo: Colori.verdeChiaro,
      colore: Colori.verde,
      peso: FontWeight.w700,
      onTap: () {
        onSlotCambiato(slot);
      },
    );
  }

  Widget _cella(
    Responsive r, {
    required String testo,
    required String descrizione,
    required Color sfondo,
    required Color colore,
    required FontWeight peso,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: descrizione,
      child: Material(
        color: sfondo,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 48,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              testo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: r.font(14),
                fontWeight: peso,
                color: colore,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
