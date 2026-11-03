import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaBloc.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaEvent.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';
import 'package:thepadel/domainLayer/enetity/risultatoPartita.dart';

import 'barraNavigazione.dart';
import 'campoPadel.dart';
import 'home.dart';
import 'invitaUtenti.dart';
import 'registraRisultato.dart';
import 'stileApp.dart';
import 'storico.dart';

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

class _DettaglioPartitaView extends StatelessWidget {
  // serve per rimandare l'evento quando l'utente tocca "Riprova"
  final int idPartita;

  const _DettaglioPartitaView({required this.idPartita});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: Colori.sfondo,
      body: SafeArea(
        child: ContenutoCentrato(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // la testata resta fuori dal builder, cosi' la freccia indietro
              // c'e' anche durante il caricamento e in errore
              const TestataIndietro(titolo: 'Dettaglio partita'),
              Expanded(
                child: BlocConsumer<DettaglioPartitaBloc, DettaglioPartitaState>(
                  listener: (context, state) {
                    // true dice alla pagina precedente di ricaricarsi,
                    // perche' la partita non e' piu' la stessa
                    if (state is PartitaEliminata) {
                      mostraSnackBar(context, 'Partita eliminata');
                      Navigator.pop(context, true);
                    }
                    if (state is UscitaCompletata) {
                      mostraSnackBar(context, 'Sei uscito dalla partita');
                      Navigator.pop(context, true);
                    }
                    if (state is PartecipazioneConfermata) {
                      // se con questa conferma ci sono tutti, la partita
                      // passa a confermata e lo diciamo
                      if (state.dettaglio.stato == 'confermata') {
                        mostraSnackBar(
                          context,
                          'Partita confermata: ci sono tutti!',
                        );
                      } else {
                        mostraSnackBar(context, 'Partecipazione confermata');
                      }
                    }
                    if (state is OperazioneErrore) {
                      mostraSnackBar(context, state.messaggio);
                    }
                  },
                  builder: (context, state) {
                    if (state is DettaglioPartitaErrore) {
                      return _buildErrore(context, r, state.messaggio);
                    }
                    if (state is DettaglioPartitaCaricato) {
                      return _buildContenuto(context, r, state.dettaglio, false);
                    }
                    if (state is PartecipazioneConfermata) {
                      return _buildContenuto(context, r, state.dettaglio, false);
                    }
                    if (state is OperazioneErrore) {
                      return _buildContenuto(context, r, state.dettaglio, false);
                    }
                    if (state is OperazioneInCorso) {
                      return _buildContenuto(context, r, state.dettaglio, true);
                    }
                    return _buildScheletro();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== CARICAMENTO =====

  Widget _buildScheletro() {
    final List<Widget> righe = [];
    for (int i = 0; i < 4; i++) {
      righe.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BarraGrigia(larghezza: 140, altezza: 16),
              SizedBox(height: 4),
              BarraGrigia(larghezza: 180, altezza: 12),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: BarraGrigia(larghezza: 240, altezza: 30),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: BarraGrigia(larghezza: 280, altezza: 16),
          ),
          const SizedBox(height: 14),
          const BarraGrigia(altezza: 200, raggio: 20),
          const SizedBox(height: 14),
          CardBianca(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: righe,
            ),
          ),
        ],
      ),
    );
  }

  // ===== ERRORE =====

  Widget _buildErrore(BuildContext context, Responsive r, String messaggio) {
    // lo stato di errore porta solo il testo: quello generico vuol dire che
    // il problema e' di rete o del server, e quindi ha senso riprovare
    if (messaggio == ErroreGenericoServer().messaggio) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: CardErrore(
          titolo: 'Non siamo riusciti a caricare la partita',
          testo: messaggio,
          onRiprova: () {
            context.read<DettaglioPartitaBloc>().add(
              DettaglioPartitaRichiesto(idPartita: idPartita),
            );
          },
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Partita non trovata', style: stileTitolo(r)),
          const SizedBox(height: 12),
          CardBianca(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Questa partita non esiste più, oppure non puoi vederla.',
                  style: stileTesto(r, base: 16),
                ),
                const SizedBox(height: 12),
                BottonePieno(
                  testo: 'Torna alla home',
                  onPressed: () {
                    tornaAllaVoce(context, const HomePage());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== CONTENUTO =====

  Widget _buildContenuto(
    BuildContext context,
    Responsive r,
    DettaglioPartita dettaglio,
    bool isLoading,
  ) {
    final RisultatoPartita? risultato = dettaglio.risultato;
    final List<Widget> azioni = _buildAzioni(context, r, dettaglio, isLoading);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildIntestazione(r, dettaglio),
                const SizedBox(height: 14),
                _buildCampo(context, dettaglio, isLoading),
                const SizedBox(height: 14),
                if (risultato != null)
                  _buildRisultato(r, dettaglio, risultato)
                else
                  _buildGiocatori(context, r, dettaglio, isLoading),
                if (risultato != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: LinkTesto(
                      testo: 'Vai allo storico',
                      onPressed: () {
                        tornaAllaVoce(context, const StoricoPage());
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (azioni.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: azioni,
            ),
          ),
      ],
    );
  }

  // su una partita annullata non si fa piu' nulla, qualunque cosa dica il server
  bool _puoInvitare(DettaglioPartita dettaglio) {
    return dettaglio.azioni.puoInvitare && dettaglio.stato != 'annullata';
  }

  // ===== INTESTAZIONE =====

  String _titolo(DettaglioPartita dettaglio) {
    final RisultatoPartita? risultato = dettaglio.risultato;

    if (risultato != null && risultato.esito != null) {
      String testo = risultato.esito == 'VINTA' ? 'Hai vinto' : 'Hai perso';
      final int? punti = risultato.puntiAssegnati;
      if (punti != null) {
        testo += punti >= 0 ? ', +$punti punti' : ', $punti punti';
      }
      return testo;
    }
    if (dettaglio.stato == 'giocata') {
      return 'Partita giocata';
    }
    final String giorno = conMaiuscola(giornoRelativo(dettaglio.dataPartita));
    return '$giorno alle ${formattaOra(dettaglio.oraInizio)}';
  }

  String _sottotitolo(DettaglioPartita dettaglio) {
    final String orario =
        '${formattaOra(dettaglio.oraInizio)} - ${formattaOra(dettaglio.oraFine)}';
    if (dettaglio.stato == 'giocata') {
      return '${conMaiuscola(dataEstesa(dettaglio.dataPartita))}, '
          '$orario · ${dettaglio.nomeCampo}';
    }
    return '${giornoEMese(dettaglio.dataPartita)}, $orario · ${dettaglio.nomeCampo}';
  }

  List<String> _nomiDaConfermare(DettaglioPartita dettaglio) {
    final List<String> nomi = [];
    for (final posto in dettaglio.posti) {
      // i giocatori del campo hanno sempre confermata false: non contano
      if (posto.tipo == 'UTENTE' && !posto.confermata) {
        nomi.add(posto.nome ?? '');
      }
    }
    return nomi;
  }

  List<Widget> _pilloleStato(DettaglioPartita dettaglio) {
    if (dettaglio.stato == 'annullata') {
      return const [
        Pillola(
          testo: 'Annullata',
          sfondo: Colori.bordo,
          colore: Colori.testo,
        ),
      ];
    }
    if (dettaglio.stato == 'confermata') {
      return const [
        Pillola(
          testo: 'Confermata, ci sono tutti',
          sfondo: Colori.verdeChiaro,
          colore: Colori.verde,
        ),
      ];
    }
    if (dettaglio.stato != 'creata') {
      return const [];
    }

    final List<Widget> pillole = [];
    if (dettaglio.postiLiberi == 1) {
      pillole.add(
        const Pillola(
          testo: 'Manca un giocatore',
          sfondo: Colori.arancioChiaro,
          colore: Colori.arancio,
        ),
      );
    } else if (dettaglio.postiLiberi > 1) {
      pillole.add(
        Pillola(
          testo: 'Mancano ${dettaglio.postiLiberi} giocatori',
          sfondo: Colori.arancioChiaro,
          colore: Colori.arancio,
        ),
      );
    } else if (_nomiDaConfermare(dettaglio).isNotEmpty) {
      pillole.add(
        const Pillola(
          testo: 'In attesa di conferma',
          sfondo: Colori.arancioChiaro,
          colore: Colori.arancio,
        ),
      );
    }
    pillole.add(
      Pillola(
        testo: dettaglio.tipo == 'PUBBLICA' ? 'Pubblica' : 'Privata',
        sfondo: Colori.bordo,
        colore: Colori.testo,
      ),
    );
    return pillole;
  }

  Widget _buildIntestazione(Responsive r, DettaglioPartita dettaglio) {
    final List<Widget> pillole = _pilloleStato(dettaglio);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_titolo(dettaglio), style: stileTitolo(r)),
        const SizedBox(height: 4),
        Text(_sottotitolo(dettaglio), style: stileSecondario(r)),
        if (pillole.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: pillole),
        ],
      ],
    );
  }

  // ===== CAMPO =====

  Widget _buildCampo(
    BuildContext context,
    DettaglioPartita dettaglio,
    bool isLoading,
  ) {
    VoidCallback? onInvita;
    if (_puoInvitare(dettaglio) && !isLoading) {
      onInvita = () {
        _apriInvita(context, dettaglio);
      };
    }

    return CampoPadel(
      altezza: dettaglio.postiLiberi > 0 ? 200 : 180,
      arrotondato: true,
      posti: postiDaDettaglio(dettaglio, conNomi: true, onInvita: onInvita),
    );
  }

  // ===== GIOCATORI =====

  Widget _buildGiocatori(
    BuildContext context,
    Responsive r,
    DettaglioPartita dettaglio,
    bool isLoading,
  ) {
    // le conferme interessano solo finche' la partita e' in attesa
    final bool inAttesa = dettaglio.stato == 'creata';
    final List<Widget> righe = [];

    for (final posto in dettaglio.posti) {
      righe.add(_rigaPosto(r, posto, dettaglio.telefonoCreatore, inAttesa));
    }
    for (int i = 0; i < dettaglio.postiLiberi; i++) {
      righe.add(_rigaPostoLibero(context, r, dettaglio, isLoading));
    }

    final List<Widget> figli = [];
    if (inAttesa) {
      figli.add(
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 2),
          child: Text(
            'Giocatori, ${dettaglio.posti.length} su 4',
            style: stileTesto(r, base: 16, peso: FontWeight.w700),
          ),
        ),
      );
    }
    for (int i = 0; i < righe.length; i++) {
      if (i > 0) {
        figli.add(const Divider(height: 1, color: Colori.bordo));
      }
      figli.add(righe[i]);
    }

    return CardBianca(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: figli,
      ),
    );
  }

  Widget _rigaPosto(
    Responsive r,
    PostoPartita posto,
    String telefonoCreatore,
    bool conStato,
  ) {
    String nome = '${posto.nome ?? ''} ${posto.cognome ?? ''}'.trim();
    String dettagli = '';

    if (posto.tipo == 'CAMPO') {
      nome = 'Giocatore del campo';
    } else {
      if (posto.telefono == telefonoCreatore) {
        dettagli = 'Organizzatore · ';
      }
      if (posto.livello != null) {
        dettagli += 'Livello ${posto.livello}';
      }
    }

    Widget? statoConferma;
    if (conStato && posto.tipo == 'UTENTE') {
      statoConferma = Text(
        posto.confermata ? 'Confermato' : 'Da confermare',
        style: stileTesto(
          r,
          base: 14,
          peso: FontWeight.w600,
          colore: posto.confermata ? Colori.verde : Colori.arancio,
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nome, style: stileTesto(r, peso: FontWeight.w600)),
                  if (dettagli.isNotEmpty)
                    Text(dettagli, style: stileSecondario(r, base: 13)),
                ],
              ),
            ),
            if (statoConferma != null) ...[
              const SizedBox(width: 8),
              statoConferma,
            ],
          ],
        ),
      ),
    );
  }

  Widget _rigaPostoLibero(
    BuildContext context,
    Responsive r,
    DettaglioPartita dettaglio,
    bool isLoading,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(child: Text('Posto libero', style: stileSecondario(r))),
          if (_puoInvitare(dettaglio))
            LinkTesto(
              testo: 'Invita',
              onPressed:
                  isLoading
                      ? null
                      : () {
                        _apriInvita(context, dettaglio);
                      },
            ),
        ],
      ),
    );
  }

  // ===== RISULTATO =====

  // i nomi di una squadra; senza squadre sui posti resta solo il numero
  String _nomiSquadra(DettaglioPartita dettaglio, int squadra) {
    final List<String> nomi = [];
    for (final posto in dettaglio.posti) {
      if (posto.squadra == squadra) {
        if (posto.tipo == 'CAMPO') {
          nomi.add('Giocatore del campo');
        } else {
          nomi.add(posto.nome ?? '');
        }
      }
    }
    if (nomi.isEmpty) {
      return 'Squadra $squadra';
    }
    return unisciNomi(nomi);
  }

  Widget _buildRisultato(
    Responsive r,
    DettaglioPartita dettaglio,
    RisultatoPartita risultato,
  ) {
    // la squadra dell'utente va in alto: il server invece le ordina per numero
    final int? mia = risultato.squadraUtente;
    final int primaSquadra = mia == 2 ? 2 : 1;
    final int secondaSquadra = mia == 2 ? 1 : 2;

    final List<Widget> titoliSet = [];
    for (int i = 0; i < risultato.set.length; i++) {
      titoliSet.add(
        SizedBox(
          width: r.font(48),
          child: Text(
            'Set ${i + 1}',
            textAlign: TextAlign.center,
            style: stileSecondario(r, base: 13),
          ),
        ),
      );
    }

    return CardBianca(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Risultato',
            style: stileTesto(r, base: 16, peso: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(children: [const Spacer(), ...titoliSet]),
          const SizedBox(height: 8),
          _rigaSquadra(r, dettaglio, risultato, primaSquadra, mia),
          const SizedBox(height: 8),
          _rigaSquadra(r, dettaglio, risultato, secondaSquadra, mia),
        ],
      ),
    );
  }

  Widget _rigaSquadra(
    Responsive r,
    DettaglioPartita dettaglio,
    RisultatoPartita risultato,
    int squadra,
    int? mia,
  ) {
    final bool eLaMia = squadra == mia;

    final List<Widget> punteggi = [];
    for (final set in risultato.set) {
      final int game = squadra == 1 ? set.squadra1 : set.squadra2;
      punteggi.add(
        SizedBox(
          width: r.font(48),
          child: Text(
            '$game',
            textAlign: TextAlign.center,
            style: stileNumero(r, 22).copyWith(
              fontWeight: eLaMia ? FontWeight.w600 : FontWeight.w500,
              color: eLaMia ? Colori.testo : Colori.testoSecondario,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _nomiSquadra(dettaglio, squadra),
                style:
                    eLaMia
                        ? stileTesto(r, peso: FontWeight.w700)
                        : stileSecondario(r),
              ),
              if (eLaMia)
                Text(
                  'La tua squadra',
                  style: stileTesto(
                    r,
                    base: 13,
                    peso: FontWeight.w600,
                    colore: Colori.verde,
                  ),
                ),
            ],
          ),
        ),
        ...punteggi,
      ],
    );
  }

  // ===== AZIONI =====

  // Cosa si puo' fare lo decide sempre il server. Solo la prima azione tra
  // conferma, risultato e invito e' un bottone pieno, le altre sono link.
  List<Widget> _buildAzioni(
    BuildContext context,
    Responsive r,
    DettaglioPartita dettaglio,
    bool isLoading,
  ) {
    if (dettaglio.stato == 'annullata') {
      return [];
    }

    final List<_Azione> principali = [];
    if (dettaglio.azioni.puoConfermare) {
      principali.add(
        _Azione('Conferma', () {
          context.read<DettaglioPartitaBloc>().add(
            ConfermaPartitaRichiesta(idPartita: dettaglio.id),
          );
        }),
      );
    }
    if (dettaglio.azioni.puoRegistrareRisultato) {
      principali.add(
        _Azione('Registra risultato', () {
          _apriRegistraRisultato(context, dettaglio);
        }),
      );
    }
    if (dettaglio.azioni.puoInvitare) {
      principali.add(
        _Azione('Invita giocatori', () {
          _apriInvita(context, dettaglio);
        }),
      );
    }

    final List<Widget> figli = [];
    for (int i = 0; i < principali.length; i++) {
      if (i == 0) {
        figli.add(
          BottonePieno(
            testo: principali[i].testo,
            altezza: 52,
            baseFont: 16,
            inCaricamento: isLoading,
            onPressed: principali[i].onPressed,
          ),
        );
        figli.add(const SizedBox(height: 4));
      } else {
        figli.add(
          LinkTesto(
            testo: principali[i].testo,
            onPressed: isLoading ? null : principali[i].onPressed,
          ),
        );
      }
    }

    if (dettaglio.azioni.puoUscire) {
      figli.add(
        LinkTesto(
          testo: 'Esci dalla partita',
          peso: FontWeight.w600,
          colore: Colori.testoSecondario,
          onPressed:
              isLoading
                  ? null
                  : () {
                    _confermaEsci(context, dettaglio.id);
                  },
        ),
      );
    }
    if (dettaglio.azioni.puoEliminare) {
      figli.add(
        LinkTesto(
          testo: 'Elimina partita',
          peso: FontWeight.w600,
          colore: Colori.rosso,
          onPressed:
              isLoading
                  ? null
                  : () {
                    _confermaElimina(context, dettaglio);
                  },
        ),
      );
    }

    // senza bottone pieno lo spinner non avrebbe dove stare
    if (isLoading && principali.isEmpty && figli.isNotEmpty) {
      figli.insert(
        0,
        const Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colori.testo,
              ),
            ),
          ),
        ),
      );
    }

    return figli;
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

    // ricarichiamo sempre: anche tornando con la freccia indietro qualche
    // invito puo' essere gia' partito
    if (context.mounted) {
      context.read<DettaglioPartitaBloc>().add(
        DettaglioPartitaRichiesto(idPartita: dettaglio.id),
      );
    }
  }

  Future<void> _apriRegistraRisultato(
    BuildContext context,
    DettaglioPartita dettaglio,
  ) async {
    final bool? registrato = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => RegistraRisultatoPage(dettaglio: dettaglio),
      ),
    );

    if (registrato == true && context.mounted) {
      context.read<DettaglioPartitaBloc>().add(
        DettaglioPartitaRichiesto(idPartita: dettaglio.id),
      );
    }
  }

  // ===== DIALOG DI CONFERMA =====

  Future<void> _confermaElimina(
    BuildContext context,
    DettaglioPartita dettaglio,
  ) async {
    // i giocatori del campo non vanno avvisati, e nemmeno chi sta eliminando
    final String? mioTelefono = telefonoUtenteCorrente();
    final List<String> altri = [];
    for (final posto in dettaglio.posti) {
      if (posto.tipo == 'UTENTE' && posto.telefono != mioTelefono) {
        altri.add(posto.nome ?? '');
      }
    }

    String testo = 'La partita verrà annullata';
    if (altri.isNotEmpty) {
      testo += ' per ${unisciNomi(altri)},';
    }
    testo +=
        ' e il ${dettaglio.nomeCampo} tornerà libero '
        '${giornoRelativo(dettaglio.dataPartita)} alle '
        '${formattaOra(dettaglio.oraInizio)}.';

    final bool confermato = await _chiediConferma(
      context,
      titolo: 'Eliminare la partita?',
      testo: testo,
      azione: 'Elimina',
    );

    if (confermato && context.mounted) {
      context.read<DettaglioPartitaBloc>().add(
        EliminaPartitaRichiesta(idPartita: dettaglio.id),
      );
    }
  }

  Future<void> _confermaEsci(BuildContext context, int idPartita) async {
    final bool confermato = await _chiediConferma(
      context,
      titolo: 'Uscire dalla partita?',
      testo: 'Il tuo posto tornerà libero.',
      azione: 'Esci',
    );

    if (confermato && context.mounted) {
      context.read<DettaglioPartitaBloc>().add(
        EsciDaPartitaRichiesta(idPartita: idPartita),
      );
    }
  }

  // restituisce true solo se l'utente tocca l'azione; con Annulla o toccando
  // fuori dal dialog non succede niente
  Future<bool> _chiediConferma(
    BuildContext context, {
    required String titolo,
    required String testo,
    required String azione,
  }) async {
    final r = Responsive(context);

    final bool? risposta = await showDialog<bool>(
      context: context,
      barrierColor: Colori.testo.withValues(alpha: 0.55),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(titolo, style: stileNumero(r, 22)),
                  const SizedBox(height: 8),
                  Text(testo, style: stileSecondario(r)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: BottonePieno(
                          testo: 'Annulla',
                          sfondo: Colori.sfondo,
                          coloreTesto: Colori.testo,
                          paddingOrizzontale: 8,
                          onPressed: () {
                            Navigator.pop(dialogContext, false);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: BottonePieno(
                          testo: azione,
                          sfondo: Colori.rosso,
                          paddingOrizzontale: 8,
                          onPressed: () {
                            Navigator.pop(dialogContext, true);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return risposta == true;
  }
}

class _Azione {
  final String testo;
  final VoidCallback onPressed;

  _Azione(this.testo, this.onPressed);
}
