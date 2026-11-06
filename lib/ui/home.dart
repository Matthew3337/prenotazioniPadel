import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/bloc/bachecaPubbliche/bachecaPubblicheBloc.dart';
import 'package:thepadel/bloc/bachecaPubbliche/bachecaPubblicheEvent.dart';
import 'package:thepadel/bloc/bachecaPubbliche/bachecaPubblicheState.dart';
import 'package:thepadel/bloc/homePage/homeBloc.dart';
import 'package:thepadel/bloc/homePage/homeEvent.dart';
import 'package:thepadel/bloc/homePage/homeState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/distaccoClassifica.dart';
import 'package:thepadel/domainLayer/enetity/partitaPubblica.dart';
import 'package:thepadel/domainLayer/enetity/prenotazione.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';
import 'package:thepadel/domainLayer/enetity/voceClassifica.dart';

import 'bachecaInviti.dart';
import 'bachecaPubbliche.dart';
import 'barraNavigazione.dart';
import 'bottoneEsci.dart';
import 'campoPadel.dart';
import 'classifica.dart';
import 'creaPartita.dart';
import 'dettaglioPartita.dart';
import 'invitaUtenti.dart';
import 'prenota.dart';
import 'stileApp.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeBloc>(
          create:
              (_) =>
                  sl<HomeBloc>()
                    ..add(const HomeProssimaPartitaRequested())
                    ..add(const HomeSlotOggiRequested())
                    ..add(const HomeClassificaRequested())
                    ..add(const HomeInvitiRequested())
                    ..add(const HomePartitePubblicheRequested()),
        ),
        // la home sa solo quante sono le partite pubbliche, ma il layout tablet
        // le elenca. Il provider e' pigro: su telefono nessuno lo legge e il
        // bloc non viene nemmeno creato
        BlocProvider<BachecaPubblicheBloc>(
          create:
              (_) =>
                  sl<BachecaPubblicheBloc>()
                    ..add(const BachecaPubblicheRichiesta()),
        ),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  void _ricaricaTutto(BuildContext context) {
    context.read<HomeBloc>()
      ..add(const HomeProssimaPartitaRequested())
      ..add(const HomeSlotOggiRequested())
      ..add(const HomeClassificaRequested())
      ..add(const HomeInvitiRequested())
      ..add(const HomePartitePubblicheRequested());

    if (Responsive(context).isTablet) {
      context.read<BachecaPubblicheBloc>().add(
        const BachecaPubblicheRichiesta(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: Colori.sfondo,
      bottomNavigationBar: const BarraNavigazione(voceAttiva: VoceBarra.home),
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (r.isTablet) {
              return _buildTablet(context, r, state);
            }
            return _buildTelefono(context, r, state);
          },
        ),
      ),
    );
  }

  // ===== LAYOUT TELEFONO =====

  Widget _buildTelefono(BuildContext context, Responsive r, HomeState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIntestazione(context, r, state),
          const SizedBox(height: 12),
          _buildProssimaPartita(context, r, state, 158),
          const SizedBox(height: 12),
          _buildContatori(context, r, state, false),
          const SizedBox(height: 12),
          _buildCampiLiberi(context, r, state),
          const SizedBox(height: 12),
          _buildClassifica(context, r, state, false),
          const SizedBox(height: 4),
          const BottoneEsci(),
        ],
      ),
    );
  }

  // ===== LAYOUT TABLET =====

  Widget _buildTablet(BuildContext context, Responsive r, HomeState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIntestazione(context, r, state),
          const SizedBox(height: 16),
          // con IntrinsicHeight le due colonne finiscono alla stessa altezza
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 62,
                  child: _buildProssimaPartita(context, r, state, 214),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 38,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildContatori(context, r, state, true)),
                      const SizedBox(height: 16),
                      _buildClassifica(context, r, state, true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildTabelloneOggi(context, r, state),
          const SizedBox(height: 16),
          _buildPubblicheTablet(context, r),
          const SizedBox(height: 4),
          const BottoneEsci(),
        ],
      ),
    );
  }

  // ===== INTESTAZIONE =====

  Widget _buildIntestazione(
    BuildContext context,
    Responsive r,
    HomeState state,
  ) {
    final sezione = state.prossimaPartita;
    final TextStyle stile =
        r.isTablet ? stileTitolo(r).copyWith(fontSize: 30) : stileTitolo(r);

    // "Domani giochi alle..." ora sta dentro la card della partita: qui resta
    // il saluto, tranne quando non c'e' nessuna partita
    Widget testi = Text(_saluto(), style: stile);
    if (sezione is SectionEmpty) {
      testi = Text('Nessuna partita in programma', style: stile);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: testi),
        const SizedBox(width: 12),
        _buildAvatar(r),
      ],
    );
  }

  // il nome lo salva il login, quindi c'e' subito e non dipende dalle chiamate
  // della home; manca solo a chi e' entrato con una versione vecchia dell'app
  String? _nomeUtente() {
    return sl<SharedPreferences>().getString('nome');
  }

  String _saluto() {
    final String? nome = _nomeUtente();
    if (nome == null || nome.isEmpty) {
      return 'Ciao';
    }
    return 'Ciao, $nome';
  }

  Widget _buildAvatar(Responsive r) {
    final String? nome = _nomeUtente();

    Widget contenuto = const Icon(
      Icons.person_outline,
      color: Colori.azzurro,
      size: 22,
    );
    if (nome != null && nome.isNotEmpty) {
      contenuto = Text(
        nome[0].toUpperCase(),
        style: stileTesto(r, peso: FontWeight.w700, colore: Colori.azzurro),
      );
    }

    return Semantics(
      label: 'Il tuo profilo',
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colori.azzurroChiaro,
          shape: BoxShape.circle,
        ),
        child: contenuto,
      ),
    );
  }

  // es. "Domani giochi alle 8:00"
  String _fraseProssimaPartita(Prenotazione partita) {
    final String giorno = conMaiuscola(
      giornoRelativo(partita.dataPrenotazione),
    );
    return '$giorno giochi alle ${formattaOra(partita.oraInizio)}';
  }

  // la barra bianca in cima alla card, come quella in fondo con lo stato
  Widget _barraFrase(Responsive r, Prenotazione partita) {
    final TextStyle stile =
        r.isTablet ? stileTitolo(r).copyWith(fontSize: 30) : stileTitolo(r);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Text(_fraseProssimaPartita(partita), style: stile),
    );
  }

  // ===== PROSSIMA PARTITA =====

  Widget _buildProssimaPartita(
    BuildContext context,
    Responsive r,
    HomeState state,
    double altezzaCampo,
  ) {
    final sezione = state.prossimaPartita;

    if (sezione is SectionLoading) {
      return _scheletroProssimaPartita(altezzaCampo);
    }

    if (sezione is SectionEmpty) {
      return _buildSenzaPartita(context, r, altezzaCampo);
    }

    if (sezione is SectionSuccess<Prenotazione>) {
      final dettaglio = state.dettaglioProssimaPartita;
      if (dettaglio is SectionLoading) {
        return _scheletroProssimaPartita(altezzaCampo);
      }
      if (dettaglio is SectionSuccess<DettaglioPartita>) {
        return _buildCardPartita(
          context,
          r,
          sezione.data,
          dettaglio.data,
          altezzaCampo,
        );
      }
      return _buildSoloPrenotazione(context, r, sezione.data);
    }

    return CardErrore(
      titolo: 'Prossima partita',
      testo: 'Non siamo riusciti a caricarla.',
      titoloRosso: false,
      onRiprova: () {
        context.read<HomeBloc>().add(const HomeProssimaPartitaRequested());
      },
    );
  }

  Widget _scheletroProssimaPartita(double altezzaCampo) {
    return CardBianca(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: BarraGrigia(larghezza: 240, altezza: 30),
          ),
          Container(height: altezzaCampo, color: Colori.bordo),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BarraGrigia(larghezza: 150, altezza: 18),
                      SizedBox(height: 6),
                      BarraGrigia(larghezza: 190, altezza: 14),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                BarraGrigia(larghezza: 84, altezza: 44, raggio: 999),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenzaPartita(
    BuildContext context,
    Responsive r,
    double altezzaCampo,
  ) {
    return CardBianca(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CampoPadel(
            altezza: altezzaCampo,
            posti: const [
              PostoCampo.vuoto(conPiu: false),
              PostoCampo.vuoto(conPiu: false),
              PostoCampo.vuoto(conPiu: false),
              PostoCampo.vuoto(conPiu: false),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: BottonePieno(
                    testo: 'Prenota un campo',
                    paddingOrizzontale: 8,
                    onPressed: () {
                      cambiaPagina(context, const PrenotaPage());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BottonePieno(
                    testo: 'Trova una partita',
                    paddingOrizzontale: 8,
                    sfondo: Colori.azzurroChiaro,
                    coloreTesto: Colori.azzurro,
                    onPressed: () {
                      cambiaPagina(context, const BachecaPubblichePage());
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPartita(
    BuildContext context,
    Responsive r,
    Prenotazione partita,
    DettaglioPartita dettaglio,
    double altezzaCampo,
  ) {
    return CardBianca(
      onTap: () {
        _apriDettaglio(context, dettaglio.id);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _barraFrase(r, partita),
          CampoPadel(
            altezza: altezzaCampo,
            dimensionePosto: r.isTablet ? 56 : 44,
            posti: postiDaDettaglio(
              dettaglio,
              onInvita:
                  dettaglio.azioni.puoInvitare
                      ? () {
                        _apriInvita(context, dettaglio);
                      }
                      : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Expanded(child: _buildStatoPartita(r, dettaglio)),
                _buildAzioneProssima(context, dettaglio),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatoPartita(Responsive r, DettaglioPartita dettaglio) {
    final List<String> daConfermare = [];
    bool ioDaConfermare = false;
    final String? mioTelefono = telefonoUtenteCorrente();

    for (final posto in dettaglio.posti) {
      // i giocatori del campo hanno sempre confermata false: non contano
      if (posto.tipo == 'UTENTE' && !posto.confermata) {
        if (posto.telefono == mioTelefono) {
          ioDaConfermare = true;
        } else {
          daConfermare.add(posto.nome ?? '');
        }
      }
    }

    // con posti liberi il titolo non c'e': i cerchi vuoti sul campo bastano
    String titolo = '';
    if (dettaglio.postiLiberi == 0) {
      titolo = 'Ci sono tutti';
      if (ioDaConfermare || daConfermare.isNotEmpty) {
        titolo = 'In attesa di conferma';
      }
    }

    String sottotitolo = 'Tutti hanno confermato';
    if (ioDaConfermare) {
      sottotitolo = 'Non hai ancora confermato';
    } else if (daConfermare.length == 1) {
      sottotitolo = '${daConfermare[0]} non ha ancora confermato';
    } else if (daConfermare.length > 1) {
      sottotitolo = '${unisciNomi(daConfermare)} non hanno ancora confermato';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titolo.isNotEmpty)
          Text(titolo, style: stileTesto(r, base: 16, peso: FontWeight.w700)),
        Text(sottotitolo, style: stileSecondario(r, base: 14)),
      ],
    );
  }

  // la conferma si fa dal dettaglio, che ha il suo bloc: qui ci si limita ad aprirlo
  Widget _buildAzioneProssima(
    BuildContext context,
    DettaglioPartita dettaglio,
  ) {
    if (dettaglio.azioni.puoConfermare) {
      return Padding(
        padding: const EdgeInsets.only(left: 12),
        child: BottonePieno(
          testo: 'Apri',
          onPressed: () {
            _apriDettaglio(context, dettaglio.id);
          },
        ),
      );
    }
    if (dettaglio.azioni.puoInvitare) {
      return Padding(
        padding: const EdgeInsets.only(left: 12),
        child: BottonePieno(
          testo: 'Invita',
          onPressed: () {
            _apriInvita(context, dettaglio);
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // il server ha dato la partita ma non il suo dettaglio: niente campo disegnato
  Widget _buildSoloPrenotazione(
    BuildContext context,
    Responsive r,
    Prenotazione partita,
  ) {
    return CardBianca(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      onTap: () {
        _apriDettaglio(context, partita.id);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _fraseProssimaPartita(partita),
            style:
                r.isTablet
                    ? stileTitolo(r).copyWith(fontSize: 30)
                    : stileTitolo(r),
          ),
          const SizedBox(height: 4),
          Text(
            '${conMaiuscola(dataEstesa(partita.dataPrenotazione))}, '
            '${formattaOra(partita.oraInizio)} - ${formattaOra(partita.oraFine)}',
            style: stileSecondario(r),
          ),
          const SizedBox(height: 4),
          Text(
            'Non siamo riusciti a caricare i giocatori.',
            style: stileTesto(r, colore: Colori.rosso),
          ),
          LinkTesto(
            testo: 'Riprova',
            onPressed: () {
              context.read<HomeBloc>().add(
                const HomeProssimaPartitaRequested(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===== CONTATORI =====

  Widget _buildContatori(
    BuildContext context,
    Responsive r,
    HomeState state,
    bool inColonna,
  ) {
    final Widget inviti = _contatore(
      context,
      r,
      sezione: state.invitiRicevuti,
      singolare: 'invito ricevuto',
      plurale: 'inviti ricevuti',
      onTap: () {
        cambiaPagina(context, const BachecaInvitiPage());
      },
      onRiprova: () {
        context.read<HomeBloc>().add(const HomeInvitiRequested());
      },
    );
    final Widget pubbliche = _contatore(
      context,
      r,
      sezione: state.partitePubblicheAperte,
      singolare: 'partita pubblica aperta',
      plurale: 'partite pubbliche aperte',
      onTap: () {
        cambiaPagina(context, const BachecaPubblichePage());
      },
      onRiprova: () {
        context.read<HomeBloc>().add(const HomePartitePubblicheRequested());
      },
    );

    if (inColonna) {
      return CardBianca(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: inviti),
            const Divider(height: 1, color: Colori.bordo),
            Expanded(child: pubbliche),
          ],
        ),
      );
    }

    return CardBianca(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: inviti),
            const VerticalDivider(width: 1, color: Colori.bordo),
            Expanded(child: pubbliche),
          ],
        ),
      ),
    );
  }

  Widget _contatore(
    BuildContext context,
    Responsive r, {
    required SectionState<int> sezione,
    required String singolare,
    required String plurale,
    required VoidCallback onTap,
    required VoidCallback onRiprova,
  }) {
    if (sezione is SectionLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BarraGrigia(larghezza: 22, altezza: 30),
            SizedBox(height: 6),
            BarraGrigia(larghezza: 120, altezza: 16),
          ],
        ),
      );
    }

    final double baseNumero = r.isTablet ? 30 : 28;

    if (sezione is SectionError) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('–', style: stileNumero(r, baseNumero)),
            Text(plurale, style: stileSecondario(r)),
            LinkTesto(testo: 'Riprova', onPressed: onRiprova),
          ],
        ),
      );
    }

    int numero = 0;
    if (sezione is SectionSuccess<int>) {
      numero = sezione.data;
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$numero', style: stileNumero(r, baseNumero)),
            Text(
              numero == 1 ? singolare : plurale,
              style: stileSecondario(r),
            ),
          ],
        ),
      ),
    );
  }

  // ===== CAMPI LIBERI OGGI =====

  Widget _titoloSlot(BuildContext context, Responsive r, String titolo) {
    return Row(
      children: [
        Expanded(
          child: Text(
            titolo,
            style: stileTesto(r, base: 16, peso: FontWeight.w700),
          ),
        ),
        LinkTesto(
          testo: 'Altri giorni',
          peso: FontWeight.w600,
          onPressed: () {
            cambiaPagina(context, const PrenotaPage());
          },
        ),
      ],
    );
  }

  Widget _buildCampiLiberi(
    BuildContext context,
    Responsive r,
    HomeState state,
  ) {
    final sezione = state.slotOggi;

    if (sezione is SectionError) {
      return CardErrore(
        titolo: 'Campi liberi oggi',
        testo: 'Non siamo riusciti a caricarli.',
        titoloRosso: false,
        onRiprova: () {
          context.read<HomeBloc>().add(const HomeSlotOggiRequested());
        },
      );
    }

    final List<Widget> righe = [_titoloSlot(context, r, 'Campi liberi oggi')];

    if (sezione is SectionLoading) {
      righe.add(const SizedBox(height: 2));
      righe.add(_rigaScheletroSlot());
      righe.add(const SizedBox(height: 8));
      righe.add(_rigaScheletroSlot());
    } else {
      // la lista comprende anche gli slot occupati: qui servono solo i liberi
      final Map<String, List<SlotOrario>> perCampo = {};
      if (sezione is SectionSuccess<List<SlotOrario>>) {
        for (final slot in sezione.data) {
          if (slot.disponibile) {
            if (!perCampo.containsKey(slot.nomeCampo)) {
              perCampo[slot.nomeCampo] = [];
            }
            perCampo[slot.nomeCampo]!.add(slot);
          }
        }
      }

      if (perCampo.isEmpty) {
        righe.add(
          Text('Nessuno slot disponibile per oggi.', style: stileSecondario(r)),
        );
      }
      for (final nomeCampo in perCampo.keys) {
        righe.add(const SizedBox(height: 2));
        righe.addAll(
          _righeCampo(context, r, nomeCampo, perCampo[nomeCampo]!),
        );
        righe.add(const SizedBox(height: 6));
      }
    }

    return CardBianca(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: righe,
      ),
    );
  }

  Widget _rigaScheletroSlot() {
    const Widget spazio = SizedBox(width: 6);
    const Widget casella = Expanded(
      child: BarraGrigia(altezza: 44, raggio: 10),
    );
    return const Row(
      children: [
        SizedBox(width: 56, child: BarraGrigia(altezza: 16)),
        SizedBox(width: 8),
        casella,
        spazio,
        casella,
        spazio,
        casella,
        spazio,
        casella,
      ],
    );
  }

  // gli orari di un campo stanno tutti su una riga, che scorre di lato se
  // non entrano nella card; il nome del campo resta fermo a sinistra
  List<Widget> _righeCampo(
    BuildContext context,
    Responsive r,
    String nomeCampo,
    List<SlotOrario> slots,
  ) {
    final List<Widget> caselle = [];
    for (int i = 0; i < slots.length; i++) {
      if (i > 0) {
        caselle.add(const SizedBox(width: 6));
      }
      caselle.add(
        SizedBox(width: r.font(64), child: _casellaSlot(context, r, slots[i])),
      );
    }

    return [
      Row(
        children: [
          SizedBox(
            width: r.font(64),
            child: Text(
              nomeCampo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: stileTesto(r, peso: FontWeight.w600),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: caselle),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _casellaSlot(BuildContext context, Responsive r, SlotOrario slot) {
    return Material(
      color: Colori.verdeChiaro,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          _apriCreaPartita(context, slot);
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          child: Text(
            oraBreve(slot.oraInizio),
            maxLines: 1,
            style: stileTesto(r, peso: FontWeight.w700, colore: Colori.verde),
          ),
        ),
      ),
    );
  }

  // ===== TABELLONE TABLET =====

  // Su tablet gli slot di oggi stanno in una griglia: una colonna per orario.
  // Il bloc ha gia' tolto quelli iniziati, quindi la griglia parte da adesso.
  Widget _buildTabelloneOggi(
    BuildContext context,
    Responsive r,
    HomeState state,
  ) {
    final sezione = state.slotOggi;

    if (sezione is SectionError) {
      return CardErrore(
        titolo: 'Campi di oggi',
        testo: 'Non siamo riusciti a caricarli.',
        titoloRosso: false,
        onRiprova: () {
          context.read<HomeBloc>().add(const HomeSlotOggiRequested());
        },
      );
    }

    final List<Widget> righe = [_titoloSlot(context, r, 'Campi di oggi')];

    if (sezione is SectionLoading) {
      righe.add(_rigaScheletroSlot());
      righe.add(const SizedBox(height: 5));
      righe.add(_rigaScheletroSlot());
    } else if (sezione is SectionSuccess<List<SlotOrario>>) {
      righe.add(_grigliaOggi(context, r, sezione.data));
    } else {
      righe.add(
        Text('Nessuno slot disponibile per oggi.', style: stileSecondario(r)),
      );
    }

    return CardBianca(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: righe,
      ),
    );
  }

  // gli orari dopo mezzanotte devono finire in fondo e non in testa, quindi
  // le prime ore del mattino contano come il giorno dopo
  int _minutiPerOrdinare(SlotOrario slot) {
    final ora = slot.inizio;
    int minuti = ora.hour * 60 + ora.minute;
    if (ora.hour < 6) {
      minuti += 24 * 60;
    }
    return minuti;
  }

  Widget _grigliaOggi(
    BuildContext context,
    Responsive r,
    List<SlotOrario> slots,
  ) {
    final Map<String, int> orari = {};
    final Map<String, Map<String, SlotOrario>> perCampo = {};
    for (final slot in slots) {
      final String ora = oraBreve(slot.oraInizio);
      orari[ora] = _minutiPerOrdinare(slot);
      if (!perCampo.containsKey(slot.nomeCampo)) {
        perCampo[slot.nomeCampo] = {};
      }
      perCampo[slot.nomeCampo]![ora] = slot;
    }
    final List<String> colonne = orari.keys.toList();
    colonne.sort((a, b) => orari[a]!.compareTo(orari[b]!));

    return LayoutBuilder(
      builder: (context, constraints) {
        const double larghezzaNome = 70;
        const double spazio = 5;
        // se gli orari sono tanti la griglia scorre dentro la sua card
        double larghezzaCella =
            (constraints.maxWidth - larghezzaNome) / colonne.length - spazio;
        if (larghezzaCella < 58) {
          larghezzaCella = 58;
        }

        final List<Widget> intestazione = [
          const SizedBox(width: larghezzaNome),
        ];
        for (final ora in colonne) {
          intestazione.add(const SizedBox(width: spazio));
          intestazione.add(
            SizedBox(
              width: larghezzaCella,
              child: Text(
                ora,
                textAlign: TextAlign.center,
                style: stileSecondario(r, base: 14).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        final List<Widget> righe = [Row(children: intestazione)];
        for (final nomeCampo in perCampo.keys) {
          final List<Widget> celle = [
            SizedBox(
              width: larghezzaNome,
              child: Text(
                nomeCampo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: stileTesto(r, peso: FontWeight.w600),
              ),
            ),
          ];
          for (final ora in colonne) {
            celle.add(const SizedBox(width: spazio));
            celle.add(
              SizedBox(
                width: larghezzaCella,
                child: _cellaOggi(context, r, perCampo[nomeCampo]![ora]),
              ),
            );
          }
          righe.add(const SizedBox(height: 5));
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
    );
  }

  Widget _cellaOggi(BuildContext context, Responsive r, SlotOrario? slot) {
    String testo = '–';
    Color colore = Colori.grigio;
    if (slot != null && !slot.disponibile) {
      testo = 'Occ.';
      colore = Colori.testoSecondario;
    }

    if (slot != null && slot.disponibile) {
      return Material(
        color: Colori.verdeChiaro,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () {
            _apriCreaPartita(context, slot);
          },
          child: Container(
            height: 48,
            alignment: Alignment.center,
            child: Text(
              'Libero',
              style: stileTesto(
                r,
                base: 14,
                peso: FontWeight.w700,
                colore: Colori.verde,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colori.sfondo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(testo, style: stileTesto(r, base: 13, colore: colore)),
    );
  }

  // ===== PARTITE PUBBLICHE TABLET =====

  Widget _buildPubblicheTablet(BuildContext context, Responsive r) {
    return BlocConsumer<BachecaPubblicheBloc, BachecaPubblicheState>(
      listener: (context, state) {
        if (state is IngressoRiuscito) {
          _apriDettaglio(context, state.dettaglio.id);
        }
        if (state is IngressoErrore) {
          mostraSnackBar(context, state.messaggio);
        }
      },
      builder: (context, state) {
        if (state is BachecaPubblicheErrore) {
          return CardErrore(
            titolo: 'Partite pubbliche',
            testo: 'Non siamo riusciti a caricarle.',
            titoloRosso: false,
            onRiprova: () {
              context.read<BachecaPubblicheBloc>().add(
                const BachecaPubblicheRichiesta(),
              );
            },
          );
        }

        List<PartitaPubblica>? partite;
        int? idInIngresso;
        if (state is BachecaPubblicheCaricata) {
          partite = state.partite;
        }
        if (state is IngressoInCorso) {
          partite = state.partite;
          idInIngresso = state.idPartita;
        }
        if (state is IngressoRiuscito) {
          partite = state.partite;
        }
        if (state is IngressoErrore) {
          partite = state.partite;
        }

        final List<Widget> righe = [
          Text(
            'Partite pubbliche',
            style: stileTesto(r, base: 17, peso: FontWeight.w700),
          ),
          const SizedBox(height: 4),
        ];

        if (partite == null) {
          righe.add(const BarraGrigia(altezza: 44));
          righe.add(const SizedBox(height: 10));
        } else if (partite.isEmpty) {
          righe.add(
            Text(
              'Nessuna partita pubblica disponibile al momento',
              style: stileSecondario(r),
            ),
          );
          righe.add(const SizedBox(height: 10));
        } else {
          for (int i = 0; i < partite.length; i++) {
            if (i > 0) {
              righe.add(const Divider(height: 1, color: Colori.bordo));
            }
            righe.add(
              _rigaPubblica(context, r, partite[i], idInIngresso),
            );
          }
        }

        return CardBianca(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: righe,
          ),
        );
      },
    );
  }

  Widget _rigaPubblica(
    BuildContext context,
    Responsive r,
    PartitaPubblica partita,
    int? idInIngresso,
  ) {
    final bool unPosto = partita.postiLiberi == 1;
    final String quando =
        '${conMaiuscola(giornoRelativo(partita.dataPartita))}, '
        '${formattaOra(partita.oraInizio)}';
    String dove =
        ' · ${partita.nomeCampo} · ${partita.nomeCreatore} '
        '${partita.cognomeCreatore}';
    // se il creatore e' un admin il livello non c'e'
    if (partita.livelloCreatore != null) {
      dove += ', livello ${partita.livelloCreatore}';
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: quando,
                    style: stileTesto(r, peso: FontWeight.w700),
                  ),
                  TextSpan(text: dove, style: stileSecondario(r)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Pillola(
            testo: unPosto ? '1 posto libero' : '${partita.postiLiberi} posti liberi',
            sfondo: unPosto ? Colori.arancioChiaro : Colori.azzurroChiaro,
            colore: unPosto ? Colori.arancio : Colori.azzurro,
          ),
          const SizedBox(width: 12),
          if (idInIngresso == partita.id)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else
            LinkTesto(
              testo: 'Entra',
              onPressed:
                  idInIngresso != null
                      ? null
                      : () {
                        context.read<BachecaPubblicheBloc>().add(
                          EntraInPartitaRichiesto(idPartita: partita.id),
                        );
                      },
            ),
        ],
      ),
    );
  }

  // ===== CLASSIFICA =====

  Widget _buildClassifica(
    BuildContext context,
    Responsive r,
    HomeState state,
    bool inColonna,
  ) {
    final sezione = state.classifica;

    if (sezione is SectionLoading) {
      return const CardBianca(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            BarraGrigia(larghezza: 48, altezza: 48, raggio: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BarraGrigia(larghezza: 180, altezza: 18),
                  SizedBox(height: 6),
                  BarraGrigia(larghezza: 220, altezza: 14),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (sezione is SectionSuccess<VoceClassifica>) {
      final VoceClassifica voce = sezione.data;
      final Widget cerchio = Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colori.arancioChiaro,
          shape: BoxShape.circle,
        ),
        child: Text(
          '${voce.posizione}°',
          style: stileNumero(r, 20).copyWith(
            fontWeight: FontWeight.w700,
            color: Colori.arancio,
          ),
        ),
      );
      final String distacco = _testoDistacco(state);
      final TextStyle stilePunti = stileTesto(
        r,
        base: r.isTablet ? 17 : 16,
        peso: FontWeight.w700,
      );

      if (inColonna) {
        return CardBianca(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          onTap: () {
            cambiaPagina(context, const ClassificaPage());
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  cerchio,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('${voce.punteggio} punti', style: stilePunti),
                  ),
                ],
              ),
              if (distacco.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(distacco, style: stileSecondario(r)),
              ],
            ],
          ),
        );
      }

      return CardBianca(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onTap: () {
          cambiaPagina(context, const ClassificaPage());
        },
        child: Row(
          children: [
            cerchio,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${voce.punteggio} punti in classifica',
                    style: stilePunti,
                  ),
                  if (distacco.isNotEmpty)
                    Text(distacco, style: stileSecondario(r, base: 14)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colori.grigio, size: 20),
          ],
        ),
      );
    }

    if (sezione is SectionEmpty) {
      return CardBianca(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colori.sfondo,
                shape: BoxShape.circle,
              ),
              child: Text('–', style: stileSecondario(r, base: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Classifica non disponibile',
                    style: stileTesto(r, base: 16, peso: FontWeight.w700),
                  ),
                  Text(
                    'Gli amministratori non compaiono tra i giocatori',
                    style: stileSecondario(r, base: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return CardErrore(
      titolo: 'La tua posizione',
      testo: 'Non siamo riusciti a caricarla.',
      titoloRosso: false,
      onRiprova: () {
        context.read<HomeBloc>().add(const HomeClassificaRequested());
      },
    );
  }

  String _testoDistacco(HomeState state) {
    final sezione = state.distaccoClassifica;
    if (sezione is! SectionSuccess<DistaccoClassifica>) {
      return '';
    }
    final int? punti = sezione.data.punti;
    final int? posizioneSopra = sezione.data.posizioneSopra;
    // chi e' primo non ha nessuno da inseguire: la riga resta vuota
    if (punti == null || posizioneSopra == null) {
      return '';
    }
    if (punti == 1) {
      return 'Ti manca 1 punto per il $posizioneSopra° posto';
    }
    return 'Ti mancano $punti punti per il $posizioneSopra° posto';
  }

  // ===== NAVIGAZIONE =====

  Future<void> _apriCreaPartita(BuildContext context, SlotOrario slot) async {
    // la home mostra gli slot di oggi, quindi la data e' quella odierna
    final int? idPartita = await Navigator.push<int>(
      context,
      MaterialPageRoute<int>(
        builder: (_) => CreaPartitaPage(slot: slot, data: DateTime.now()),
      ),
    );

    // l'id arriva solo se la partita e' stata creata: si resta in home e si
    // ricaricano le sezioni, cosi' la nuova partita compare in evidenza
    if (idPartita != null && context.mounted) {
      _ricaricaTutto(context);
    }
  }

  Future<void> _apriDettaglio(BuildContext context, int idPartita) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => DettaglioPartitaPage(idPartita: idPartita),
      ),
    );

    // ricarichiamo sempre: dopo un risultato registrato la pagina torna con
    // la freccia indietro, senza true, ma il punteggio in classifica e' cambiato
    if (context.mounted) {
      _ricaricaTutto(context);
    }
  }

  Future<void> _apriInvita(
    BuildContext context,
    DettaglioPartita dettaglio,
  ) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder:
            (_) => InvitaUtentiPage(
              idPartita: dettaglio.id,
              dettaglio: dettaglio,
            ),
      ),
    );

    if (context.mounted) {
      _ricaricaTutto(context);
    }
  }
}
