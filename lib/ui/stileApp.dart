import 'package:flutter/material.dart';

import 'fontApp.dart';

// Colori, misure e piccoli pezzi grafici usati da tutte le pagine: stanno
// qui per non ricopiarli in ogni file e per tenere le pagine uguali tra loro.

class Colori {
  static const Color sfondo = Color(0xFFF7F8FC);
  static const Color primario = Color(0xFF4564B1);
  static const Color bluCampo = Color(0xFF3F5DA8);
  static const Color testo = Color(0xFF252B3A);
  static const Color testoSecondario = Color(0xFF353B48);
  // solo per bordi, icone e disabilitato: sui testi normali non si legge bene
  static const Color grigio = Color(0xFF7D8597);
  static const Color bordo = Color(0xFFE0E3EA);

  static const Color verdeChiaro = Color(0xFFE0F4EE);
  static const Color verde = Color(0xFF075E50);
  static const Color rossoChiaro = Color(0xFFFBE3E3);
  static const Color rosso = Color(0xFFA33A3A);
  static const Color arancioChiaro = Color(0xFFFFF0D9);
  static const Color arancio = Color(0xFF92530B);
  static const Color azzurroChiaro = Color(0xFFE7F1FC);
  static const Color azzurro = Color(0xFF2168B4);

  // solo per i bottoni di login e registrazione
  static const Color bluAcceso = Color(0xFF2F5BD3);
}

// I font sono scalati sulla larghezza di un iPhone standard (390): cosi' su
// un iPhone SE il testo si stringe un po' e su un tablet cresce di poco.
class Responsive {
  final double width;
  final bool isTablet;
  final double textScale;

  Responsive(BuildContext context)
    : width = MediaQuery.sizeOf(context).width,
      isTablet = MediaQuery.sizeOf(context).width >= 600,
      textScale = (MediaQuery.sizeOf(context).width / 390).clamp(0.85, 1.1);

  double font(double base) => base * textScale;

  double get maxContentWidth => isTablet ? 640 : double.infinity;
}

// Il font dei titoli e' variabile: Flutter non ricava lo spessore dal solo
// fontWeight, quindi lo si passa anche come asse 'wght'.
TextStyle stileTitolo(Responsive r) {
  return TextStyle(
    fontFamily: FontApp.titoli,
    fontWeight: FontWeight.w600,
    fontVariations: const [FontVariation.weight(600)],
    fontSize: r.font(26),
    height: 1.15,
    letterSpacing: -0.26,
    color: Colori.testo,
  );
}

// i numeri grandi e i titoli delle card, con il font dei titoli
TextStyle stileNumero(Responsive r, double base) {
  return TextStyle(
    fontFamily: FontApp.titoli,
    fontWeight: FontWeight.w600,
    fontVariations: const [FontVariation.weight(600)],
    fontSize: r.font(base),
    height: 1.2,
    color: Colori.testo,
  );
}

TextStyle stileTesto(
  Responsive r, {
  double base = 15,
  FontWeight peso = FontWeight.w400,
  Color colore = Colori.testo,
}) {
  return TextStyle(
    fontFamily: FontApp.testo,
    fontSize: r.font(base),
    fontWeight: peso,
    height: 1.4,
    color: colore,
  );
}

TextStyle stileSecondario(Responsive r, {double base = 15}) {
  return stileTesto(r, base: base, colore: Colori.testoSecondario);
}

// ===== DATE E ORARI =====

const List<String> _giorniSettimana = [
  'lunedì',
  'martedì',
  'mercoledì',
  'giovedì',
  'venerdì',
  'sabato',
  'domenica',
];

const List<String> _mesi = [
  'gennaio',
  'febbraio',
  'marzo',
  'aprile',
  'maggio',
  'giugno',
  'luglio',
  'agosto',
  'settembre',
  'ottobre',
  'novembre',
  'dicembre',
];

String conMaiuscola(String testo) {
  if (testo.isEmpty) {
    return testo;
  }
  return testo[0].toUpperCase() + testo.substring(1);
}

// DateTime.weekday parte da 1 per il lunedi'
String nomeGiorno(DateTime data) {
  return _giorniSettimana[data.weekday - 1];
}

// es. "5 novembre"
String giornoEMese(DateTime data) {
  return '${data.day} ${_mesi[data.month - 1]}';
}

// es. "giovedì 5 novembre"
String dataEstesa(DateTime data) {
  return '${nomeGiorno(data)} ${giornoEMese(data)}';
}

// "oggi", "domani" oppure il nome del giorno, sempre in minuscolo
String giornoRelativo(DateTime data) {
  final adesso = DateTime.now();
  final oggi = DateTime(adesso.year, adesso.month, adesso.day);
  final giorno = DateTime(data.year, data.month, data.day);
  if (giorno == oggi) {
    return 'oggi';
  }
  // uso il costruttore e non add(Duration): col cambio dell'ora legale un
  // giorno non e' sempre di 24 ore
  if (giorno == DateTime(oggi.year, oggi.month, oggi.day + 1)) {
    return 'domani';
  }
  return nomeGiorno(data);
}

String formattaOra(TimeOfDay ora) {
  final ore = ora.hour.toString().padLeft(2, '0');
  final minuti = ora.minute.toString().padLeft(2, '0');
  return '$ore:$minuti';
}

// gli slot portano l'ora come testo, a volte con i secondi: a noi bastano
// ore e minuti
String oraBreve(String ora) {
  if (ora.length > 5) {
    return ora.substring(0, 5);
  }
  return ora;
}

// Una partita che finisce prima dell'ora d'inizio (es. 23:00 - 00:30) finisce
// il giorno dopo la sua data.
DateTime fineDellaPartita(
  DateTime dataPartita,
  TimeOfDay oraInizio,
  TimeOfDay oraFine,
) {
  final int minutiInizio = oraInizio.hour * 60 + oraInizio.minute;
  final int minutiFine = oraFine.hour * 60 + oraFine.minute;
  int giornoFine = dataPartita.day;
  if (minutiFine <= minutiInizio) {
    giornoFine = dataPartita.day + 1;
  }
  return DateTime(
    dataPartita.year,
    dataPartita.month,
    giornoFine,
    oraFine.hour,
    oraFine.minute,
  );
}

// Il risultato si registra entro 24 ore dalla fine della partita: passato
// questo termine puo' inserirlo solo l'amministratore. Uso il costruttore e
// non add(Duration) per lo stesso motivo di giornoRelativo.
bool termineRisultatoScaduto(
  DateTime dataPartita,
  TimeOfDay oraInizio,
  TimeOfDay oraFine,
) {
  final DateTime fine = fineDellaPartita(dataPartita, oraInizio, oraFine);
  final DateTime termine = DateTime(
    fine.year,
    fine.month,
    fine.day + 1,
    fine.hour,
    fine.minute,
  );
  return DateTime.now().isAfter(termine);
}

// "Sara", "Sara e Luca", "Sara, Luca ed Elena"
String unisciNomi(List<String> nomi) {
  String risultato = '';
  for (int i = 0; i < nomi.length; i++) {
    if (i > 0) {
      if (i == nomi.length - 1) {
        final bool vocale = nomi[i].startsWith('E') || nomi[i].startsWith('e');
        risultato += vocale ? ' ed ' : ' e ';
      } else {
        risultato += ', ';
      }
    }
    risultato += nomi[i];
  }
  return risultato;
}

// "1 posto libero", "3 posti liberi"
String testoPostiLiberi(int posti) {
  if (posti == 0) {
    return 'Nessun posto libero';
  }
  if (posti == 1) {
    return '1 posto libero';
  }
  return '$posti posti liberi';
}

// ===== SNACKBAR =====

void mostraSnackBar(BuildContext context, String testo) {
  final r = Responsive(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        testo,
        style: stileTesto(r, peso: FontWeight.w600, colore: Colors.white),
      ),
      backgroundColor: Colori.testo,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

// ===== WIDGET COMUNI =====

// il contenuto delle pagine resta centrato e largo al massimo 640 sui tablet
class ContenutoCentrato extends StatelessWidget {
  final Widget child;

  const ContenutoCentrato({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: r.maxContentWidth),
        child: child,
      ),
    );
  }
}

class CardBianca extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const CardBianca({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colori.bordo),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class Pillola extends StatelessWidget {
  final String testo;
  final Color sfondo;
  final Color colore;

  const Pillola({
    super.key,
    required this.testo,
    required this.sfondo,
    required this.colore,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: sfondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        testo,
        style: stileTesto(r, base: 13, peso: FontWeight.w600, colore: colore),
      ),
    );
  }
}

// lo stato di una partita, che il server manda in minuscolo
class PillolaStato extends StatelessWidget {
  final String stato;

  const PillolaStato({super.key, required this.stato});

  @override
  Widget build(BuildContext context) {
    if (stato == 'confermata') {
      return const Pillola(
        testo: 'Confermata',
        sfondo: Colori.verdeChiaro,
        colore: Colori.verde,
      );
    }
    if (stato == 'creata') {
      return const Pillola(
        testo: 'Creata',
        sfondo: Colori.arancioChiaro,
        colore: Colori.arancio,
      );
    }
    return Pillola(
      testo: conMaiuscola(stato),
      sfondo: Colori.bordo,
      colore: Colori.testo,
    );
  }
}

// bottone a pillola senza ombra. In caricamento mostra lo spinner e resta
// disabilitato; con onPressed a null diventa grigio
class BottonePieno extends StatelessWidget {
  final String testo;
  final VoidCallback? onPressed;
  final bool inCaricamento;
  final double altezza;
  final double baseFont;
  final Color sfondo;
  final Color coloreTesto;
  final double paddingOrizzontale;

  const BottonePieno({
    super.key,
    required this.testo,
    required this.onPressed,
    this.inCaricamento = false,
    this.altezza = 44,
    this.baseFont = 15,
    this.sfondo = Colori.primario,
    this.coloreTesto = Colors.white,
    this.paddingOrizzontale = 20,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final VoidCallback? azione = inCaricamento ? null : onPressed;

    return ElevatedButton(
      onPressed: azione,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: Size(0, altezza),
        padding: EdgeInsets.symmetric(horizontal: paddingOrizzontale),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: sfondo,
        foregroundColor: coloreTesto,
        disabledBackgroundColor: Colori.bordo,
        disabledForegroundColor: Colori.testoSecondario,
        shape: const StadiumBorder(),
      ),
      child:
          inCaricamento
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colori.testo,
                ),
              )
              : Text(
                testo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: r.font(baseFont),
                  fontWeight: FontWeight.w700,
                ),
              ),
    );
  }
}

// un'azione di solo testo, comunque alta 44 per essere facile da toccare
class LinkTesto extends StatelessWidget {
  final String testo;
  final VoidCallback? onPressed;
  final Color colore;
  final FontWeight peso;

  const LinkTesto({
    super.key,
    required this.testo,
    required this.onPressed,
    this.colore = Colori.bluCampo,
    this.peso = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: colore,
        disabledForegroundColor: Colori.grigio,
      ),
      child: Text(
        testo,
        style: TextStyle(fontSize: r.font(15), fontWeight: peso),
      ),
    );
  }
}

// il campo per cercare un utente per nome: il debounce lo fa la pagina
class CampoRicerca extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const CampoRicerca({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    const OutlineInputBorder bordo = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Colori.grigio),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cerca per nome', style: stileTesto(r, peso: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: stileTesto(r),
          decoration: InputDecoration(
            hintText: 'Nome o cognome',
            hintStyle: stileSecondario(r),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: bordo,
            enabledBorder: bordo,
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: Colori.azzurro, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// la barra grigia del caricamento: occupa lo spazio del testo che arrivera'
class BarraGrigia extends StatelessWidget {
  final double? larghezza;
  final double altezza;
  final double raggio;

  const BarraGrigia({
    super.key,
    this.larghezza,
    required this.altezza,
    this.raggio = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: larghezza,
      height: altezza,
      decoration: BoxDecoration(
        color: Colori.bordo,
        borderRadius: BorderRadius.circular(raggio),
      ),
    );
  }
}

// cerchio con le iniziali su una tinta
class CerchioIniziali extends StatelessWidget {
  final String testo;
  final Color sfondo;
  final Color colore;
  final double dimensione;

  const CerchioIniziali({
    super.key,
    required this.testo,
    required this.sfondo,
    required this.colore,
    this.dimensione = 44,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Container(
      width: dimensione,
      height: dimensione,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: sfondo, shape: BoxShape.circle),
      child: Text(
        testo,
        style: TextStyle(
          color: colore,
          fontWeight: FontWeight.w700,
          fontSize: r.font(15),
        ),
      ),
    );
  }
}

// l'errore di una sezione: titolo, spiegazione e "Riprova" dentro la card
class CardErrore extends StatelessWidget {
  final String titolo;
  final String? testo;
  final bool titoloRosso;
  final VoidCallback onRiprova;

  const CardErrore({
    super.key,
    required this.titolo,
    this.testo,
    this.titoloRosso = true,
    required this.onRiprova,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return SizedBox(
      width: double.infinity,
      child: CardBianca(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titolo,
              style: stileTesto(
                r,
                base: 16,
                peso: FontWeight.w700,
                colore: titoloRosso ? Colori.rosso : Colori.testo,
              ),
            ),
            if (testo != null) ...[
              const SizedBox(height: 4),
              Text(
                testo!,
                style:
                    titoloRosso
                        ? stileSecondario(r)
                        : stileTesto(r, colore: Colori.rosso),
              ),
            ],
            LinkTesto(testo: 'Riprova', onPressed: onRiprova),
          ],
        ),
      ),
    );
  }
}

// riquadro colorato per i messaggi dei form
class RiquadroMessaggio extends StatelessWidget {
  final String testo;
  final Color sfondo;
  final Color colore;
  final Widget? azione;

  const RiquadroMessaggio({
    super.key,
    required this.testo,
    this.sfondo = Colori.rossoChiaro,
    this.colore = Colori.rosso,
    this.azione,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: sfondo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              testo,
              style: stileTesto(r, peso: FontWeight.w600, colore: colore),
            ),
          ),
          if (azione != null) azione!,
        ],
      ),
    );
  }
}

// la testata delle pagine di dettaglio: freccia indietro e titolo
class TestataIndietro extends StatelessWidget {
  final String titolo;
  final VoidCallback? onIndietro;

  const TestataIndietro({super.key, required this.titolo, this.onIndietro});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Indietro',
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: Colori.testo,
              ),
              onPressed:
                  onIndietro ??
                  () {
                    Navigator.pop(context);
                  },
            ),
            Expanded(
              child: Text(
                titolo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: stileTesto(r, peso: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// la finestra di dialogo delle pagine admin: titolo e contenuto a scelta
class FinestraDialogo extends StatelessWidget {
  final String titolo;
  final List<Widget> figli;

  const FinestraDialogo({super.key, required this.titolo, required this.figli});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              ...figli,
            ],
          ),
        ),
      ),
    );
  }
}

// la richiesta di conferma prima di un'azione rossa: chiude il dialog
// restituendo true solo se si tocca il bottone di conferma
class FinestraConferma extends StatelessWidget {
  final String titolo;
  final String testo;
  final String testoConferma;

  const FinestraConferma({
    super.key,
    required this.titolo,
    required this.testo,
    required this.testoConferma,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return FinestraDialogo(
      titolo: titolo,
      figli: [
        Text(testo, style: stileSecondario(r)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: BottonePieno(
                testo: 'Indietro',
                sfondo: Colori.sfondo,
                coloreTesto: Colori.testo,
                paddingOrizzontale: 8,
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: BottonePieno(
                testo: testoConferma,
                sfondo: Colori.rosso,
                paddingOrizzontale: 8,
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
