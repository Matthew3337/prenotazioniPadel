import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/dettaglioAdmin/dettaglioAdminBloc.dart';
import 'package:thepadel/bloc/dettaglioAdmin/dettaglioAdminEvent.dart';
import 'package:thepadel/bloc/dettaglioAdmin/dettaglioAdminState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';
import 'package:thepadel/domainLayer/enetity/risultatoPartita.dart';

import 'campoPadel.dart';
import 'modificaPartecipanti.dart';
import 'modificaRisultato.dart';
import 'stileApp.dart';

class DettaglioAdminPage extends StatelessWidget {
  final int idPartita;

  const DettaglioAdminPage({super.key, required this.idPartita});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DettaglioAdminBloc>(
      create:
          (_) =>
              sl<DettaglioAdminBloc>()
                ..add(DettaglioAdminRichiesto(id: idPartita)),
      child: _DettaglioAdminView(idPartita: idPartita),
    );
  }
}

class _DettaglioAdminView extends StatelessWidget {
  // serve per rimandare l'evento quando l'admin tocca "Riprova"
  final int idPartita;

  const _DettaglioAdminView({required this.idPartita});

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
                child: BlocConsumer<DettaglioAdminBloc, DettaglioAdminState>(
                  listener: (context, state) {
                    // Il bloc e' condiviso con le pagine di modifica: finche'
                    // una e' aperta sopra questa, i messaggi li mostra lei.
                    // Senza questo controllo uscirebbero due volte.
                    final bool inPrimoPiano =
                        ModalRoute.of(context)?.isCurrent ?? true;
                    if (!inPrimoPiano) {
                      return;
                    }
                    if (state is OperazioneAdminRiuscita) {
                      mostraSnackBar(context, state.messaggio);
                    }
                    if (state is OperazioneAdminErrore) {
                      mostraSnackBar(context, state.messaggio);
                    }
                  },
                  builder: (context, state) {
                    if (state is DettaglioAdminErrore) {
                      return _buildErrore(context, state.messaggio);
                    }
                    if (state is DettaglioAdminCaricato) {
                      return _buildContenuto(
                        context,
                        r,
                        state.dettaglio,
                        false,
                      );
                    }
                    if (state is OperazioneAdminRiuscita) {
                      return _buildContenuto(
                        context,
                        r,
                        state.dettaglio,
                        false,
                      );
                    }
                    if (state is OperazioneAdminErrore) {
                      return _buildContenuto(
                        context,
                        r,
                        state.dettaglio,
                        false,
                      );
                    }
                    if (state is OperazioneAdminInCorso) {
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
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: BarraGrigia(larghezza: 240, altezza: 30),
          ),
          SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: BarraGrigia(larghezza: 220, altezza: 16),
          ),
          SizedBox(height: 14),
          BarraGrigia(altezza: 200, raggio: 20),
          SizedBox(height: 14),
          BarraGrigia(altezza: 160, raggio: 20),
        ],
      ),
    );
  }

  // ===== ERRORE =====

  Widget _buildErrore(BuildContext context, String messaggio) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: CardErrore(
        titolo: 'Non siamo riusciti a caricare la partita',
        testo: messaggio,
        onRiprova: () {
          context.read<DettaglioAdminBloc>().add(
            DettaglioAdminRichiesto(id: idPartita),
          );
        },
      ),
    );
  }

  // ===== CONTENUTO =====

  // i bottoni stanno nella parte che scorre: sono tanti e, fissi in basso, su
  // un telefono piccolo lascerebbero poco spazio alla partita
  Widget _buildContenuto(
    BuildContext context,
    Responsive r,
    DettaglioPartita dettaglio,
    bool isLoading,
  ) {
    final RisultatoPartita? risultato = dettaglio.risultato;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIntestazione(r, dettaglio),
          const SizedBox(height: 14),
          CampoPadel(
            altezza: dettaglio.postiLiberi > 0 ? 200 : 180,
            arrotondato: true,
            posti: postiDaDettaglio(dettaglio, conNomi: true),
          ),
          const SizedBox(height: 14),
          if (risultato != null && risultato.set.isNotEmpty) ...[
            _buildRisultato(r, dettaglio, risultato),
            const SizedBox(height: 14),
          ],
          _buildGiocatori(context, r, dettaglio, isLoading),
          const SizedBox(height: 16),
          ..._buildAzioni(context, dettaglio, isLoading),
        ],
      ),
    );
  }

  // ===== INTESTAZIONE =====

  Widget _buildIntestazione(Responsive r, DettaglioPartita dettaglio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          conMaiuscola(dataEstesa(dettaglio.dataPartita)),
          style: stileTitolo(r),
        ),
        const SizedBox(height: 4),
        Text(
          '${formattaOra(dettaglio.oraInizio)} - ${formattaOra(dettaglio.oraFine)}'
          ' · ${dettaglio.nomeCampo}',
          style: stileSecondario(r),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            PillolaStato(stato: dettaglio.stato),
            Pillola(
              testo: dettaglio.tipo == 'PUBBLICA' ? 'Pubblica' : 'Privata',
              sfondo: Colori.bordo,
              colore: Colori.testo,
            ),
          ],
        ),
      ],
    );
  }

  // ===== GIOCATORI =====

  // il server rifiuta le modifiche su queste partite: meglio non proporle
  bool _partecipantiModificabili(DettaglioPartita dettaglio) {
    return dettaglio.stato != 'annullata' && dettaglio.stato != 'giocata';
  }

  Widget _buildGiocatori(
    BuildContext context,
    Responsive r,
    DettaglioPartita dettaglio,
    bool isLoading,
  ) {
    final List<Widget> righe = [];
    for (final posto in dettaglio.posti) {
      righe.add(_rigaPosto(context, r, posto, dettaglio, isLoading));
    }
    for (int i = 0; i < dettaglio.postiLiberi; i++) {
      righe.add(
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Posto libero', style: stileSecondario(r)),
          ),
        ),
      );
    }

    final List<Widget> figli = [
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 2),
        child: Text(
          'Giocatori, ${dettaglio.posti.length} su 4',
          style: stileTesto(r, base: 16, peso: FontWeight.w700),
        ),
      ),
    ];
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
    BuildContext context,
    Responsive r,
    PostoPartita posto,
    DettaglioPartita dettaglio,
    bool isLoading,
  ) {
    // le conferme interessano solo finche' la partita e' in attesa
    final bool conStato = dettaglio.stato == 'creata';
    final int? idPosto = posto.idPosto;

    String nome = '${posto.nome ?? ''} ${posto.cognome ?? ''}'.trim();
    final List<String> dettagli = [];

    if (posto.tipo == 'CAMPO') {
      nome = 'Giocatore del campo';
    } else {
      if (posto.telefono == dettaglio.telefonoCreatore) {
        dettagli.add('Organizzatore');
      }
      if (posto.livello != null) {
        dettagli.add('Livello ${posto.livello}');
      }
    }
    if (posto.squadra != null) {
      dettagli.add('Squadra ${posto.squadra}');
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
                    Text(
                      dettagli.join(' · '),
                      style: stileSecondario(r, base: 13),
                    ),
                ],
              ),
            ),
            if (conStato && posto.tipo == 'UTENTE') ...[
              const SizedBox(width: 8),
              Text(
                posto.confermata ? 'Confermato' : 'Da confermare',
                style: stileTesto(
                  r,
                  base: 14,
                  peso: FontWeight.w600,
                  colore: posto.confermata ? Colori.verde : Colori.arancio,
                ),
              ),
            ],
            if (posto.tipo == 'CAMPO' &&
                idPosto != null &&
                _partecipantiModificabili(dettaglio)) ...[
              const SizedBox(width: 8),
              LinkTesto(
                testo: 'Rimuovi',
                colore: Colori.rosso,
                onPressed:
                    isLoading
                        ? null
                        : () {
                          _confermaRimozione(context, dettaglio, idPosto);
                        },
              ),
            ],
          ],
        ),
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
          _rigaSquadra(r, dettaglio, risultato, 1),
          const SizedBox(height: 8),
          _rigaSquadra(r, dettaglio, risultato, 2),
        ],
      ),
    );
  }

  Widget _rigaSquadra(
    Responsive r,
    DettaglioPartita dettaglio,
    RisultatoPartita risultato,
    int squadra,
  ) {
    final List<Widget> punteggi = [];
    for (final set in risultato.set) {
      final int game = squadra == 1 ? set.squadra1 : set.squadra2;
      punteggi.add(
        SizedBox(
          width: r.font(48),
          child: Text(
            '$game',
            textAlign: TextAlign.center,
            style: stileNumero(r, 22),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            _nomiSquadra(dettaglio, squadra),
            style: stileSecondario(r),
          ),
        ),
        ...punteggi,
      ],
    );
  }

  // ===== AZIONI =====

  List<Widget> _buildAzioni(
    BuildContext context,
    DettaglioPartita dettaglio,
    bool isLoading,
  ) {
    final bool partecipantiModificabili = _partecipantiModificabili(dettaglio);
    final bool risultatoModificabile =
        dettaglio.stato == 'confermata' || dettaglio.stato == 'giocata';

    return [
      if (isLoading)
        const Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colori.bluCampo,
              ),
            ),
          ),
        ),
      if (partecipantiModificabili) ...[
        BottonePieno(
          testo: 'Modifica partecipanti',
          onPressed:
              isLoading
                  ? null
                  : () {
                    _apriModificaPartecipanti(context, dettaglio);
                  },
        ),
        const SizedBox(height: 8),
      ],
      if (partecipantiModificabili && dettaglio.postiLiberi > 0) ...[
        BottonePieno(
          testo: 'Aggiungi giocatori campo',
          onPressed:
              isLoading
                  ? null
                  : () {
                    _scegliGiocatoriCampo(context, dettaglio);
                  },
        ),
        const SizedBox(height: 8),
      ],
      if (risultatoModificabile) ...[
        BottonePieno(
          testo: 'Modifica risultato',
          onPressed:
              isLoading
                  ? null
                  : () {
                    _apriModificaRisultato(context, dettaglio);
                  },
        ),
        const SizedBox(height: 8),
      ],
      BottonePieno(
        testo: 'Modifica stato',
        sfondo: Colori.azzurroChiaro,
        coloreTesto: Colori.azzurro,
        onPressed:
            isLoading
                ? null
                : () {
                  _scegliStato(context, dettaglio);
                },
      ),
      if (dettaglio.stato != 'annullata') ...[
        const SizedBox(height: 4),
        LinkTesto(
          testo: 'Annulla partita',
          peso: FontWeight.w600,
          colore: Colori.rosso,
          onPressed:
              isLoading
                  ? null
                  : () {
                    _confermaAnnulla(context, dettaglio);
                  },
        ),
      ],
    ];
  }

  // Le pagine di modifica ricevono questo stesso bloc: con uno nuovo preso da
  // sl il dettaglio qui sotto non saprebbe nulla delle loro operazioni.
  void _apriModificaPartecipanti(
    BuildContext context,
    DettaglioPartita dettaglio,
  ) {
    final DettaglioAdminBloc bloc = context.read<DettaglioAdminBloc>();
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder:
            (_) => ModificaPartecipantiPage(dettaglio: dettaglio, bloc: bloc),
      ),
    );
  }

  void _apriModificaRisultato(
    BuildContext context,
    DettaglioPartita dettaglio,
  ) {
    final DettaglioAdminBloc bloc = context.read<DettaglioAdminBloc>();
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ModificaRisultatoPage(dettaglio: dettaglio, bloc: bloc),
      ),
    );
  }

  // ===== DIALOG =====

  Future<void> _scegliStato(
    BuildContext context,
    DettaglioPartita dettaglio,
  ) async {
    final r = Responsive(context);
    const List<String> stati = ['creata', 'confermata', 'annullata', 'giocata'];

    final String? scelto = await showDialog<String>(
      context: context,
      barrierColor: Colori.testo.withValues(alpha: 0.55),
      builder: (dialogContext) {
        final List<Widget> voci = [];
        for (final stato in stati) {
          final bool attuale = stato == dettaglio.stato;
          voci.add(
            InkWell(
              // scegliere lo stato che ha gia' non cambierebbe nulla
              onTap:
                  attuale
                      ? null
                      : () {
                        Navigator.pop(dialogContext, stato);
                      },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        conMaiuscola(stato),
                        style: stileTesto(r, base: 16),
                      ),
                    ),
                    if (attuale)
                      const Pillola(
                        testo: 'Attuale',
                        sfondo: Colori.bordo,
                        colore: Colori.testo,
                      ),
                  ],
                ),
              ),
            ),
          );
        }

        return FinestraDialogo(
          titolo: 'Modifica stato',
          figli: [
            ...voci,
            const SizedBox(height: 8),
            BottonePieno(
              testo: 'Chiudi',
              sfondo: Colori.sfondo,
              coloreTesto: Colori.testo,
              onPressed: () {
                Navigator.pop(dialogContext);
              },
            ),
          ],
        );
      },
    );

    if (scelto != null && context.mounted) {
      context.read<DettaglioAdminBloc>().add(
        ModificaStatoRichiesta(id: dettaglio.id, stato: scelto),
      );
    }
  }

  Future<void> _confermaAnnulla(
    BuildContext context,
    DettaglioPartita dettaglio,
  ) async {
    final bool? confermato = await showDialog<bool>(
      context: context,
      barrierColor: Colori.testo.withValues(alpha: 0.55),
      builder: (dialogContext) {
        return FinestraConferma(
          titolo: 'Annullare la partita?',
          testo:
              'La partita di ${giornoEMese(dettaglio.dataPartita)} alle '
              '${formattaOra(dettaglio.oraInizio)} sul ${dettaglio.nomeCampo} '
              'verrà annullata per tutti i giocatori.',
          testoConferma: 'Annulla partita',
        );
      },
    );

    if (confermato == true && context.mounted) {
      context.read<DettaglioAdminBloc>().add(
        AnnullaPartitaRichiesta(id: dettaglio.id),
      );
    }
  }

  Future<void> _scegliGiocatoriCampo(
    BuildContext context,
    DettaglioPartita dettaglio,
  ) async {
    final r = Responsive(context);

    // il server ne accetta al massimo 3 per volta, e mai piu' dei posti liberi
    int massimo = dettaglio.postiLiberi;
    if (massimo > 3) {
      massimo = 3;
    }

    final int? scelto = await showDialog<int>(
      context: context,
      barrierColor: Colori.testo.withValues(alpha: 0.55),
      builder: (dialogContext) {
        final List<Widget> voci = [];
        for (int numero = 1; numero <= massimo; numero++) {
          voci.add(
            InkWell(
              onTap: () {
                Navigator.pop(dialogContext, numero);
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    numero == 1 ? '1 giocatore' : '$numero giocatori',
                    style: stileTesto(r, base: 16),
                  ),
                ),
              ),
            ),
          );
        }

        return FinestraDialogo(
          titolo: 'Aggiungi giocatori campo',
          figli: [
            ...voci,
            const SizedBox(height: 8),
            BottonePieno(
              testo: 'Chiudi',
              sfondo: Colori.sfondo,
              coloreTesto: Colori.testo,
              onPressed: () {
                Navigator.pop(dialogContext);
              },
            ),
          ],
        );
      },
    );

    if (scelto != null && context.mounted) {
      context.read<DettaglioAdminBloc>().add(
        AggiungiGiocatoriCampoRichiesta(id: dettaglio.id, numero: scelto),
      );
    }
  }

  Future<void> _confermaRimozione(
    BuildContext context,
    DettaglioPartita dettaglio,
    int idPosto,
  ) async {
    // lo stato non cambia da solo: una partita confermata che resta senza
    // quattro giocatori viene annullata solo quando arriva l'ora d'inizio
    String testo = 'Il posto tornerà libero.';
    if (dettaglio.stato == 'confermata') {
      testo =
          'Il posto tornerà libero. Se all\'inizio mancherà ancora un '
          'giocatore, la partita verrà annullata.';
    }

    final bool? confermato = await showDialog<bool>(
      context: context,
      barrierColor: Colori.testo.withValues(alpha: 0.55),
      builder: (dialogContext) {
        return FinestraConferma(
          titolo: 'Rimuovere il giocatore del campo?',
          testo: testo,
          testoConferma: 'Rimuovi',
        );
      },
    );

    if (confermato == true && context.mounted) {
      context.read<DettaglioAdminBloc>().add(
        RimuoviGiocatoreCampoRichiesta(id: dettaglio.id, idPosto: idPosto),
      );
    }
  }
}
