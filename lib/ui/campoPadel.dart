import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';

import 'stileApp.dart';

// Un posto da disegnare sul campo. La posizione nella lista dice dove sta:
// 0 e 1 a sinistra (squadra 1), 2 e 3 a destra (squadra 2).
class PostoCampo {
  final String iniziali;
  final Color sfondo;
  final Color colore;
  final String? nome;
  final bool libero;
  final bool conPiu;
  final String? descrizione;
  final VoidCallback? onTap;

  const PostoCampo({
    required this.iniziali,
    required this.sfondo,
    required this.colore,
    this.nome,
    this.libero = false,
    this.conPiu = true,
    this.descrizione,
    this.onTap,
  });

  const PostoCampo.vuoto({this.nome, this.conPiu = true, this.onTap})
    : iniziali = '',
      sfondo = Colors.transparent,
      colore = Colors.white,
      libero = true,
      descrizione = 'Posto libero';
}

// Il telefono salvato al login: serve a riconoscere il proprio posto nelle
// partite, il server non segna quale sia.
String? telefonoUtenteCorrente() {
  return sl<SharedPreferences>().getString('telefono');
}

String inizialiDi(String? nome, String? cognome) {
  String risultato = '';
  if (nome != null && nome.isNotEmpty) {
    risultato += nome[0];
  }
  if (cognome != null && cognome.isNotEmpty) {
    risultato += cognome[0];
  }
  return risultato.toUpperCase();
}

// Prepara i posti di una partita: chi ha gia' una squadra va dal suo lato,
// altrimenti valgono l'ordine del server e i posti liberi in fondo.
List<PostoCampo> postiDaDettaglio(
  DettaglioPartita dettaglio, {
  bool conNomi = false,
  VoidCallback? onInvita,
}) {
  final String? mioTelefono = telefonoUtenteCorrente();

  final List<PostoPartita> ordinati = [];
  for (final posto in dettaglio.posti) {
    if (posto.squadra == 1) {
      ordinati.add(posto);
    }
  }
  for (final posto in dettaglio.posti) {
    if (posto.squadra != 1) {
      ordinati.add(posto);
    }
  }

  // il blu e' riservato a chi guarda: agli altri tocca una tinta per uno
  const List<Color> sfondi = [
    Colori.verdeChiaro,
    Colori.arancioChiaro,
    Colori.rossoChiaro,
  ];
  const List<Color> colori = [Colori.verde, Colori.arancio, Colori.rosso];
  int tinta = 0;

  final List<PostoCampo> risultato = [];
  for (final posto in ordinati) {
    if (posto.tipo == 'CAMPO') {
      risultato.add(
        PostoCampo(
          iniziali: 'C',
          sfondo: Colori.bordo,
          colore: Colori.testo,
          nome: conNomi ? 'Del campo' : null,
          descrizione: 'Giocatore del campo',
        ),
      );
    } else if (posto.telefono != null && posto.telefono == mioTelefono) {
      risultato.add(
        PostoCampo(
          iniziali: 'Tu',
          sfondo: Colori.azzurroChiaro,
          colore: Colori.azzurro,
          nome: conNomi ? posto.nome : null,
          descrizione: 'Tu',
        ),
      );
    } else {
      risultato.add(
        PostoCampo(
          iniziali: inizialiDi(posto.nome, posto.cognome),
          sfondo: sfondi[tinta % sfondi.length],
          colore: colori[tinta % colori.length],
          nome: conNomi ? posto.nome : null,
          descrizione: '${posto.nome ?? ''} ${posto.cognome ?? ''}'.trim(),
        ),
      );
      tinta++;
    }
  }

  for (int i = 0; i < dettaglio.postiLiberi; i++) {
    if (onInvita != null) {
      risultato.add(
        PostoCampo.vuoto(nome: conNomi ? 'Invita' : null, onTap: onInvita),
      );
    } else {
      risultato.add(const PostoCampo.vuoto(conPiu: false));
    }
  }
  return risultato;
}

// Il campo disegnato. Le misure sono in proporzione alla larghezza, cosi'
// lo stesso widget va bene dal piu' piccolo iPhone al tablet.
class CampoPadel extends StatelessWidget {
  final double altezza;
  final List<PostoCampo> posti;
  final double dimensionePosto;
  final bool arrotondato;

  const CampoPadel({
    super.key,
    required this.altezza,
    required this.posti,
    this.dimensionePosto = 44,
    this.arrotondato = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget campo = LayoutBuilder(
      builder: (context, constraints) {
        final double larghezza = constraints.maxWidth;
        final List<Widget> figli = [
          Positioned.fill(child: CustomPaint(painter: _LineeCampoPainter())),
        ];

        // i centri dei quattro posti, presi dalle proporzioni dei prototipi
        const List<double> centriX = [0.331, 0.331, 0.669, 0.669];
        const List<double> centriY = [0.28, 0.72, 0.28, 0.72];

        for (int i = 0; i < posti.length && i < 4; i++) {
          final PostoCampo posto = posti[i];
          // con il nome sotto il blocco e' piu' largo e piu' alto del cerchio
          final double larghezzaBlocco =
              posto.nome != null ? larghezza * 0.24 : dimensionePosto;
          final double altezzaBlocco =
              posto.nome != null ? dimensionePosto + 26 : dimensionePosto;

          figli.add(
            Positioned(
              left: larghezza * centriX[i] - larghezzaBlocco / 2,
              top: altezza * centriY[i] - altezzaBlocco / 2,
              width: larghezzaBlocco,
              height: altezzaBlocco,
              child: _PostoSulCampo(
                posto: posto,
                dimensione: dimensionePosto,
              ),
            ),
          );
        }

        return Stack(children: figli);
      },
    );

    return Container(
      height: altezza,
      width: double.infinity,
      clipBehavior: arrotondato ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: Colori.bluCampo,
        borderRadius: arrotondato ? BorderRadius.circular(20) : null,
      ),
      child: campo,
    );
  }
}

class _PostoSulCampo extends StatelessWidget {
  final PostoCampo posto;
  final double dimensione;

  const _PostoSulCampo({required this.posto, required this.dimensione});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    Widget cerchio;
    if (posto.libero) {
      cerchio = SizedBox(
        width: dimensione,
        height: dimensione,
        child: CustomPaint(
          painter: CerchioTratteggiatoPainter(spessore: 2, trattino: 6),
          child: Center(
            child:
                posto.conPiu
                    ? Text(
                      '+',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: r.font(22),
                        height: 1,
                      ),
                    )
                    : null,
          ),
        ),
      );
    } else {
      cerchio = Container(
        width: dimensione,
        height: dimensione,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: posto.sfondo, shape: BoxShape.circle),
        child: Text(
          posto.iniziali,
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            color: posto.colore,
            fontWeight: FontWeight.w700,
            fontSize: r.font(15),
          ),
        ),
      );
    }

    Widget contenuto = cerchio;
    if (posto.nome != null) {
      contenuto = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          cerchio,
          const SizedBox(height: 2),
          Text(
            posto.nome!,
            // i posti hanno una misura fissa: i nomi completi, che seguono le
            // impostazioni del telefono, stanno comunque nella lista sotto
            textScaler: TextScaler.noScaling,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: r.font(13),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (posto.onTap == null) {
      return Semantics(label: posto.descrizione, child: contenuto);
    }

    return Semantics(
      button: true,
      label: posto.descrizione,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: posto.onTap,
        child: contenuto,
      ),
    );
  }
}

class _LineeCampoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint linee =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    final double margineX = size.width * 0.04;
    final double margineY = size.height * 0.075;
    final double servizioSinistra = size.width * 0.174;
    final double servizioDestra = size.width - servizioSinistra;
    final double centroX = size.width / 2;
    final double centroY = size.height / 2;

    canvas.drawRect(
      Rect.fromLTRB(
        margineX,
        margineY,
        size.width - margineX,
        size.height - margineY,
      ),
      linee,
    );
    canvas.drawLine(
      Offset(servizioSinistra, margineY),
      Offset(servizioSinistra, size.height - margineY),
      linee,
    );
    canvas.drawLine(
      Offset(servizioDestra, margineY),
      Offset(servizioDestra, size.height - margineY),
      linee,
    );
    canvas.drawLine(
      Offset(servizioSinistra, centroY),
      Offset(servizioDestra, centroY),
      linee,
    );

    // la rete sporge un po' dal rettangolo, come nei prototipi
    final Paint rete =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 3;
    canvas.drawLine(
      Offset(centroX, margineY / 2),
      Offset(centroX, size.height - margineY / 2),
      rete,
    );
  }

  @override
  bool shouldRepaint(_LineeCampoPainter oldDelegate) => false;
}

// Il bordo del posto libero: Flutter non ha i bordi tratteggiati, quindi
// disegno tanti piccoli archi lungo il cerchio.
class CerchioTratteggiatoPainter extends CustomPainter {
  final double spessore;
  final double trattino;

  CerchioTratteggiatoPainter({required this.spessore, required this.trattino});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pennello =
        Paint()
          ..color = Colors.white
          ..strokeWidth = spessore
          ..style = PaintingStyle.stroke;

    final double raggio = size.shortestSide / 2 - spessore / 2;
    final Rect cerchio = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: raggio,
    );

    // tratto e vuoto hanno la stessa lunghezza
    final int numeroTratti = (2 * pi * raggio / (trattino * 2)).floor();
    final double passo = 2 * pi / numeroTratti;
    for (int i = 0; i < numeroTratti; i++) {
      canvas.drawArc(cerchio, i * passo, passo / 2, false, pennello);
    }
  }

  @override
  bool shouldRepaint(CerchioTratteggiatoPainter oldDelegate) => false;
}

// Il campo piccolo delle partite pubbliche: dice a colpo d'occhio quanti
// posti restano.
class MiniCampo extends StatelessWidget {
  final int postiLiberi;

  const MiniCampo({super.key, required this.postiLiberi});

  @override
  Widget build(BuildContext context) {
    final int occupati = 4 - postiLiberi;
    return Semantics(
      label: '$occupati posti occupati, $postiLiberi liberi',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 76,
          height: 46,
          child: CustomPaint(painter: _MiniCampoPainter(occupati: occupati)),
        ),
      ),
    );
  }
}

class _MiniCampoPainter extends CustomPainter {
  final int occupati;

  _MiniCampoPainter({required this.occupati});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colori.bluCampo);

    final Paint rete =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2;
    canvas.drawLine(const Offset(38, 4), const Offset(38, 42), rete);

    const List<Offset> centri = [
      Offset(20, 14),
      Offset(20, 32),
      Offset(56, 14),
      Offset(56, 32),
    ];

    final Paint pieno = Paint()..color = Colors.white;
    final CerchioTratteggiatoPainter tratteggio = CerchioTratteggiatoPainter(
      spessore: 1.5,
      trattino: 2,
    );

    for (int i = 0; i < centri.length; i++) {
      if (i < occupati) {
        canvas.drawCircle(centri[i], 6, pieno);
      } else {
        canvas.save();
        canvas.translate(centri[i].dx - 5.75, centri[i].dy - 5.75);
        tratteggio.paint(canvas, const Size(11.5, 11.5));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_MiniCampoPainter oldDelegate) {
    return oldDelegate.occupati != occupati;
  }
}
