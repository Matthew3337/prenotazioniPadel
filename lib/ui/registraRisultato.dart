import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/registraRisultato/registraRisultatoBloc.dart';
import 'package:thepadel/bloc/registraRisultato/registraRisultatoEvent.dart';
import 'package:thepadel/bloc/registraRisultato/registraRisultatoState.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';
import 'package:thepadel/domainLayer/enetity/risultatoPartita.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';

import 'campoPadel.dart';
import 'stileApp.dart';

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

class _RegistraRisultatoView extends StatefulWidget {
  final DettaglioPartita dettaglio;

  const _RegistraRisultatoView({required this.dettaglio});

  @override
  State<_RegistraRisultatoView> createState() => _RegistraRisultatoViewState();
}

class _RegistraRisultatoViewState extends State<_RegistraRisultatoView> {
  // l'ultimo errore del server, sopra il bottone finche' non si riprova
  String? _errore;

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final String titolo =
        '${conMaiuscola(dataEstesa(widget.dettaglio.dataPartita))}, '
        '${widget.dettaglio.nomeCampo}';

    return Scaffold(
      backgroundColor: Colori.sfondo,
      body: SafeArea(
        child: ContenutoCentrato(
          child: BlocConsumer<RegistraRisultatoBloc, RegistraRisultatoState>(
            listener: (context, state) {
              if (state is RisultatoRegistrato) {
                mostraSnackBar(context, 'Risultato registrato');
                // true dice al dettaglio di ricaricarsi
                Navigator.pop(context, true);
              }
              if (state is RegistraRisultatoErrore) {
                setState(() {
                  _errore = state.messaggio;
                });
              }
            },
            builder: (context, state) {
              final bool isLoading = state is RegistraRisultatoLoading;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TestataIndietro(titolo: titolo),
                  Expanded(
                    child:
                        squadreComponibili(widget.dettaglio)
                            ? _buildForm(context, isLoading)
                            : _buildNonDisponibile(context, r),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isLoading) {
    return FormRisultato(
      dettaglio: widget.dettaglio,
      isLoading: isLoading,
      errore: _errore,
      onCambiato: () {
        setState(() {
          _errore = null;
        });
      },
      onSalva: (squadra1, squadra2, set) {
        context.read<RegistraRisultatoBloc>().add(
          RegistraRisultatoRichiesto(
            idPartita: widget.dettaglio.id,
            squadra1: squadra1,
            squadra2: squadra2,
            set: set,
          ),
        );
      },
    );
  }

  Widget _buildNonDisponibile(BuildContext context, Responsive r) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Registra risultato', style: stileTitolo(r)),
          const SizedBox(height: 12),
          CardBianca(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Registrazione del risultato non disponibile al momento',
                  style: stileTesto(r, base: 16, peso: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Non abbiamo potuto caricare i giocatori di questa partita.',
                  style: stileSecondario(r),
                ),
                const SizedBox(height: 12),
                BottonePieno(
                  testo: 'Torna indietro',
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

// servono quattro giocatori, tutti con il loro idPosto: senza non possiamo
// comporre le squadre. Succede se il server non manda il campo
bool squadreComponibili(DettaglioPartita dettaglio) {
  if (dettaglio.posti.length != 4) {
    return false;
  }
  for (final posto in dettaglio.posti) {
    if (posto.idPosto == null) {
      return false;
    }
  }
  return true;
}

// Il form con squadre e set, senza bloc: lo usano sia la pagina dell'utente
// sia quella dell'admin, ognuna manda al proprio bloc quello che riceve in
// onSalva. Se la partita ha gia' un risultato parte da quello.
class FormRisultato extends StatefulWidget {
  final DettaglioPartita dettaglio;
  final bool isLoading;
  final String? errore;
  // avvisa la pagina che l'utente ha toccato qualcosa: l'errore non vale piu'
  final VoidCallback onCambiato;
  final void Function(
    List<int> squadra1,
    List<int> squadra2,
    List<SetPartita> set,
  )
  onSalva;

  const FormRisultato({
    super.key,
    required this.dettaglio,
    required this.isLoading,
    required this.errore,
    required this.onCambiato,
    required this.onSalva,
  });

  @override
  State<FormRisultato> createState() => _FormRisultatoState();
}

class _FormRisultatoState extends State<FormRisultato> {
  static const int maxGame = 6;

  // i posti nello stesso ordine in cui li disegna postiDaDettaglio: quelli
  // della squadra 1 davanti, cosi' un risultato esistente parte gia' diviso
  final List<PostoPartita> _posti = [];

  // quale posto di _posti sta in ogni punto del campo: gli indici 0 e 1
  // sono la squadra 1 (a sinistra), gli indici 2 e 3 la squadra 2
  final List<int> _ordine = [0, 1, 2, 3];

  // i game dei tre set: la posizione nella lista e' il numero del set
  final List<int> _gameSquadra1 = [0, 0, 0];
  final List<int> _gameSquadra2 = [0, 0, 0];

  bool _terzoSetGiocato = false;

  int get _numeroSet => _terzoSetGiocato ? 3 : 2;

  @override
  void initState() {
    super.initState();

    for (final posto in widget.dettaglio.posti) {
      if (posto.squadra == 1) {
        _posti.add(posto);
      }
    }
    for (final posto in widget.dettaglio.posti) {
      if (posto.squadra != 1) {
        _posti.add(posto);
      }
    }

    final RisultatoPartita? risultato = widget.dettaglio.risultato;
    if (risultato != null) {
      for (int i = 0; i < risultato.set.length && i < 3; i++) {
        _gameSquadra1[i] = risultato.set[i].squadra1;
        _gameSquadra2[i] = risultato.set[i].squadra2;
      }
      _terzoSetGiocato = risultato.set.length >= 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final bool isLoading = widget.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Chi ha giocato con chi?', style: stileTitolo(r)),
                const SizedBox(height: 12),
                _buildCampo(isLoading),
                const SizedBox(height: 8),
                _buildNomiSquadre(r),
                const SizedBox(height: 6),
                Text(
                  'Tocca un giocatore per cambiarlo di squadra.',
                  style: stileSecondario(r, base: 14),
                ),
                const SizedBox(height: 12),
                _buildSet(r, isLoading),
              ],
            ),
          ),
        ),
        _buildFondo(r, isLoading),
      ],
    );
  }

  // ===== SQUADRE =====

  String _nomePosto(PostoPartita posto) {
    if (posto.tipo == 'CAMPO') {
      return 'Giocatore del campo';
    }
    return posto.nome ?? '';
  }

  // il posto toccato si scambia con quello di fronte, cosi' le squadre
  // restano sempre da due giocatori
  void _scambia(int punto) {
    setState(() {
      final int opposto = (punto + 2) % 4;
      final int appoggio = _ordine[punto];
      _ordine[punto] = _ordine[opposto];
      _ordine[opposto] = appoggio;
    });
    widget.onCambiato();
  }

  Widget _buildCampo(bool isLoading) {
    // postiDaDettaglio mette i posti nello stesso ordine di _posti
    final List<PostoCampo> disegnati = postiDaDettaglio(widget.dettaglio);

    final List<PostoCampo> posti = [];
    for (int punto = 0; punto < 4; punto++) {
      final PostoCampo base = disegnati[_ordine[punto]];
      final String nome = _nomePosto(_posti[_ordine[punto]]);
      posti.add(
        PostoCampo(
          iniziali: base.iniziali,
          sfondo: base.sfondo,
          colore: base.colore,
          descrizione: "$nome: sposta nell'altra squadra",
          onTap:
              isLoading
                  ? null
                  : () {
                    _scambia(punto);
                  },
        ),
      );
    }

    return CampoPadel(
      altezza: 164,
      dimensionePosto: 48,
      arrotondato: true,
      posti: posti,
    );
  }

  String _nomiSquadra(int primo, int secondo) {
    final String nomePrimo = _nomePosto(_posti[_ordine[primo]]);
    final String nomeSecondo = _nomePosto(_posti[_ordine[secondo]]);
    return unisciNomi([nomePrimo, nomeSecondo]);
  }

  Widget _buildNomiSquadre(Responsive r) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _colonnaSquadra(r, 'Squadra 1', _nomiSquadra(0, 1))),
        const SizedBox(width: 8),
        Expanded(child: _colonnaSquadra(r, 'Squadra 2', _nomiSquadra(2, 3))),
      ],
    );
  }

  Widget _colonnaSquadra(Responsive r, String titolo, String nomi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titolo, style: stileTesto(r, peso: FontWeight.w700)),
        Text(nomi, style: stileSecondario(r)),
      ],
    );
  }

  // ===== SET =====

  // Il primo set in parita', oppure -1. Un set ancora 0-0 non e' un errore:
  // la pagina si apre cosi' e diventare subito rossa non avrebbe senso.
  int _primoSetInParita() {
    for (int i = 0; i < _numeroSet; i++) {
      final int a = _gameSquadra1[i];
      final int b = _gameSquadra2[i];
      if (a == b && a != 0) {
        return i;
      }
    }
    return -1;
  }

  bool _haSetVuoti() {
    for (int i = 0; i < _numeroSet; i++) {
      if (_gameSquadra1[i] == 0 && _gameSquadra2[i] == 0) {
        return true;
      }
    }
    return false;
  }

  Widget _buildSet(Responsive r, bool isLoading) {
    final int setInParita = _primoSetInParita();

    final List<Widget> righe = [];
    for (int i = 0; i < _numeroSet; i++) {
      righe.add(_rigaSet(r, i, isLoading));
    }
    if (setInParita >= 0) {
      righe.add(
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Text(
            'Un set non può finire in parità: correggi il set ${setInParita + 1}.',
            style: stileTesto(r, peso: FontWeight.w600, colore: Colori.rosso),
          ),
        ),
      );
    }
    righe.add(
      Align(
        alignment: Alignment.centerLeft,
        child: LinkTesto(
          testo: _terzoSetGiocato ? 'Togli il terzo set' : 'Aggiungi il terzo set',
          onPressed:
              isLoading
                  ? null
                  : () {
                    setState(() {
                      _terzoSetGiocato = !_terzoSetGiocato;
                    });
                    widget.onCambiato();
                  },
        ),
      ),
    );

    return CardBianca(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: righe,
      ),
    );
  }

  Widget _rigaSet(Responsive r, int indice, bool isLoading) {
    final int a = _gameSquadra1[indice];
    final int b = _gameSquadra2[indice];
    final bool inParita = a == b && a != 0;

    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: inParita ? Colori.rossoChiaro : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: r.font(44),
            child: Text(
              'Set ${indice + 1}',
              style: stileTesto(
                r,
                peso: FontWeight.w700,
                colore: inParita ? Colori.rosso : Colori.testo,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(child: _stepper(r, indice, 1, a, inParita, isLoading)),
          const SizedBox(width: 6),
          Expanded(child: _stepper(r, indice, 2, b, inParita, isLoading)),
        ],
      ),
    );
  }

  Widget _stepper(
    Responsive r,
    int indiceSet,
    int squadra,
    int valore,
    bool inParita,
    bool isLoading,
  ) {
    final String nome = 'Set ${indiceSet + 1}, squadra $squadra';

    return Row(
      children: [
        _bottoneStepper(
          r,
          testo: '−',
          descrizione: '$nome, meno uno',
          sfondo: inParita ? Colors.white : Colori.sfondo,
          abilitato: !isLoading && valore > 0,
          onPressed: () {
            _cambiaGame(indiceSet, squadra, valore - 1);
          },
        ),
        Expanded(
          child: Text(
            '$valore',
            textAlign: TextAlign.center,
            style: stileNumero(r, 22),
          ),
        ),
        _bottoneStepper(
          r,
          testo: '+',
          descrizione: '$nome, più uno',
          sfondo: inParita ? Colors.white : Colori.sfondo,
          abilitato: !isLoading && valore < maxGame,
          onPressed: () {
            _cambiaGame(indiceSet, squadra, valore + 1);
          },
        ),
      ],
    );
  }

  Widget _bottoneStepper(
    Responsive r, {
    required String testo,
    required String descrizione,
    required Color sfondo,
    required bool abilitato,
    required VoidCallback onPressed,
  }) {
    return Semantics(
      button: true,
      label: descrizione,
      child: Material(
        color: sfondo,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: abilitato ? onPressed : null,
          child: SizedBox(
            width: 36,
            height: 44,
            child: Center(
              child: Text(
                testo,
                style: TextStyle(
                  fontSize: r.font(20),
                  color: abilitato ? Colori.testo : Colori.grigio,
                ),
              ),
            ),
          ),
        ),
      ),
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
    widget.onCambiato();
  }

  // ===== ESITO E SALVA =====

  String _testoEsito() {
    if (_haSetVuoti()) {
      return 'Inserisci il punteggio dei set';
    }
    int vinti1 = 0;
    int vinti2 = 0;
    for (int i = 0; i < _numeroSet; i++) {
      if (_gameSquadra1[i] > _gameSquadra2[i]) {
        vinti1++;
      }
      if (_gameSquadra2[i] > _gameSquadra1[i]) {
        vinti2++;
      }
    }
    if (vinti1 > vinti2) {
      return 'Vince la squadra 1, $vinti1 set a $vinti2';
    }
    if (vinti2 > vinti1) {
      return 'Vince la squadra 2, $vinti2 set a $vinti1';
    }
    return 'Parità: controlla i punteggi';
  }

  // i controlli su squadre e set li fa il BLoC: qui raccogliamo solo i dati
  void _salva() {
    final List<int> squadra1 = [];
    final List<int> squadra2 = [];
    for (int punto = 0; punto < 4; punto++) {
      final int idPosto = _posti[_ordine[punto]].idPosto!;
      if (punto < 2) {
        squadra1.add(idPosto);
      } else {
        squadra2.add(idPosto);
      }
    }

    final List<SetPartita> set = [];
    for (int i = 0; i < _numeroSet; i++) {
      set.add(SetPartita(squadra1: _gameSquadra1[i], squadra2: _gameSquadra2[i]));
    }

    widget.onCambiato();
    widget.onSalva(squadra1, squadra2, set);
  }

  Widget _buildFondo(Responsive r, bool isLoading) {
    // un 6-6 e un 0-0 sono entrambi set in parita': il server li rifiuterebbe
    final bool salvabile = _primoSetInParita() < 0 && !_haSetVuoti();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.errore != null) ...[
            RiquadroMessaggio(testo: widget.errore!),
            const SizedBox(height: 8),
          ],
          if (_primoSetInParita() < 0) ...[
            Text(
              _testoEsito(),
              textAlign: TextAlign.center,
              style: stileTesto(r, peso: FontWeight.w600),
            ),
            const SizedBox(height: 8),
          ],
          BottonePieno(
            testo: 'Salva risultato',
            altezza: 52,
            baseFont: 16,
            inCaricamento: isLoading,
            onPressed:
                salvabile
                    ? _salva
                    : null,
          ),
        ],
      ),
    );
  }
}
