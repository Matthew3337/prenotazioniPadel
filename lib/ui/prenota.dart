import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/prenota/prenotaBloc.dart';
import 'package:thepadel/bloc/prenota/prenotaEvent.dart';
import 'package:thepadel/bloc/prenota/prenotaState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/campo.dart';
import 'package:thepadel/domainLayer/enetity/partitaStorico.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';

import 'barraNavigazione.dart';
import 'creaPartita.dart';
import 'dettaglioPartita.dart';
import 'stileApp.dart';

class PrenotaPage extends StatelessWidget {
  // da "Vedi tutti gli orari" si arriva qui con il giorno gia' scelto
  final DateTime? giornoIniziale;

  const PrenotaPage({super.key, this.giornoIniziale});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PrenotaBloc>(
      create: (_) {
        final bloc = sl<PrenotaBloc>();
        final DateTime? giorno = giornoIniziale;
        if (giorno != null) {
          bloc.add(PrenotaGiornoCambiato(giorno: giorno));
        } else {
          bloc.add(const PrenotaRichiesta());
        }
        return bloc;
      },
      child: const _PrenotaView(),
    );
  }
}

class _PrenotaView extends StatefulWidget {
  const _PrenotaView();

  @override
  State<_PrenotaView> createState() => _PrenotaViewState();
}

class _PrenotaViewState extends State<_PrenotaView> {
  // lo slot toccato e non ancora confermato con "Continua"
  SlotOrario? _slotScelto;

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: Colori.sfondo,
      bottomNavigationBar: const BarraNavigazione(
        voceAttiva: VoceBarra.prenota,
      ),
      body: SafeArea(
        child: ContenutoCentrato(
          child: BlocBuilder<PrenotaBloc, PrenotaState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Prenota un campo', style: stileTitolo(r)),
                          const SizedBox(height: 4),
                          _buildSottotitolo(r, state),
                          const SizedBox(height: 12),
                          _buildGiorni(context, r, state),
                          const SizedBox(height: 12),
                          _buildContenuto(context, r, state),
                        ],
                      ),
                    ),
                  ),
                  // resta fuori dallo scorrimento: il tabellone puo' essere
                  // lungo e "Continua" deve vedersi subito dopo il tocco
                  if (_slotScelto != null && state is PrenotaCaricato)
                    _buildScelta(context, r, state, _slotScelto!),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ===== INTESTAZIONE =====

  Widget _buildSottotitolo(Responsive r, PrenotaState state) {
    String testo = conMaiuscola(dataEstesa(state.giorno));
    if (state is PrenotaCaricato) {
      final int liberi = _contaLiberi(state);
      testo += liberi == 1 ? ' · 1 slot libero' : ' · $liberi slot liberi';
    }
    return Text(testo, style: stileSecondario(r));
  }

  int _contaLiberi(PrenotaCaricato state) {
    final DateTime adesso = DateTime.now();
    int liberi = 0;
    for (final campo in state.campi) {
      final List<SlotOrario> slots = state.slotPerCampo[campo.id] ?? [];
      for (final slot in slots) {
        if (slot.disponibile &&
            !state.slotPassato(slot, adesso) &&
            state.partitaUtenteDelloSlot(slot) == null) {
          liberi++;
        }
      }
    }
    return liberi;
  }

  // ===== GIORNI =====

  Widget _buildGiorni(BuildContext context, Responsive r, PrenotaState state) {
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
                  setState(() {
                    _slotScelto = null;
                  });
                  context.read<PrenotaBloc>().add(
                    PrenotaGiornoCambiato(giorno: giorno),
                  );
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

  // ===== TABELLONE =====

  Widget _buildContenuto(
    BuildContext context,
    Responsive r,
    PrenotaState state,
  ) {
    if (state is PrenotaErrore) {
      return CardErrore(
        titolo:
            'Non siamo riusciti a caricare gli orari di ${nomeGiorno(state.giorno)}',
        testo: 'Puoi riprovare o scegliere un altro giorno.',
        onRiprova: () {
          context.read<PrenotaBloc>().add(const PrenotaRichiesta());
        },
      );
    }

    if (state is PrenotaCaricato) {
      return _buildTabellone(context, r, state);
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

  Widget _buildTabellone(
    BuildContext context,
    Responsive r,
    PrenotaCaricato state,
  ) {
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
                    context,
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
    BuildContext context,
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
    final PartitaStorico? mia = state.partitaUtenteDelloSlot(slot);
    if (mia != null) {
      return _cella(
        r,
        testo: 'La tua partita',
        descrizione: nomeOra,
        sfondo: Colori.azzurroChiaro,
        colore: Colori.azzurro,
        peso: FontWeight.w700,
        onTap: () {
          _apriDettaglio(context, mia.id);
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

    final SlotOrario? scelto = _slotScelto;
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
          setState(() {
            _slotScelto = null;
          });
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
        setState(() {
          _slotScelto = slot;
        });
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

  // ===== SCELTA =====

  Widget _buildScelta(
    BuildContext context,
    Responsive r,
    PrenotaCaricato state,
    SlotOrario slot,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: CardBianca(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${slot.nomeCampo}, ${nomeGiorno(state.giorno)} ${state.giorno.day}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: stileTesto(r, peso: FontWeight.w700),
                  ),
                  Text(
                    '${oraBreve(slot.oraInizio)} - ${oraBreve(slot.oraFine)}',
                    style: stileSecondario(r, base: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            BottonePieno(
              testo: 'Continua',
              onPressed: () {
                _apriCreaPartita(context, state, slot);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===== NAVIGAZIONE =====

  Future<void> _apriCreaPartita(
    BuildContext context,
    PrenotaCaricato state,
    SlotOrario slot,
  ) async {
    bool? alCoperto;
    for (final campo in state.campi) {
      if (campo.id == slot.idCampo) {
        alCoperto = campo.alCoperto;
      }
    }

    final int? idPartita = await Navigator.push<int>(
      context,
      MaterialPageRoute<int>(
        builder:
            (_) => CreaPartitaPage(
              slot: slot,
              data: state.giorno,
              alCoperto: alCoperto,
            ),
      ),
    );

    // se la partita e' stata creata ricarico il tabellone e apro subito il
    // suo dettaglio, come fa la home
    if (idPartita != null && context.mounted) {
      setState(() {
        _slotScelto = null;
      });
      context.read<PrenotaBloc>().add(const PrenotaRichiesta());
      await _apriDettaglio(context, idPartita);
    }
  }

  Future<void> _apriDettaglio(BuildContext context, int idPartita) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => DettaglioPartitaPage(idPartita: idPartita),
      ),
    );

    if (context.mounted) {
      context.read<PrenotaBloc>().add(const PrenotaRichiesta());
    }
  }
}
